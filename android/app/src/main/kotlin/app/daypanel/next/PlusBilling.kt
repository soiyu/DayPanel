package app.daypanel.next

import android.app.Activity
import android.content.Context
import android.util.Base64
import com.android.billingclient.api.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import org.json.JSONObject

/** Play receipts are device-local and excluded from business backups. Never trust a Dart bool. */
object PlusReceipt {
    fun valid(data:String, signature:String, publicKey:String, packageName:String, product:String):Boolean = try {
        val key=KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(Base64.decode(publicKey,Base64.DEFAULT)))
        val verifier=Signature.getInstance("SHA1withRSA")
        verifier.initVerify(key);verifier.update(data.toByteArray(Charsets.UTF_8))
        val json=JSONObject(data)
        verifier.verify(Base64.decode(signature,Base64.DEFAULT)) && json.optString("packageName")==packageName &&
            json.optString("productId")==product && json.optInt("purchaseState",-1)==0 && json.optString("purchaseToken").isNotBlank()
    } catch(_:Exception){false}
    fun owned(c:Context):Boolean {
        if(BuildConfig.DEBUG)return true
        val p=c.getSharedPreferences("play_receipt",Context.MODE_PRIVATE)
        return valid(p.getString("data","")!!,p.getString("signature","")!!,BuildConfig.PLAY_PUBLIC_KEY,c.packageName,BuildConfig.PLUS_PRODUCT_ID)
    }
}

class PlusBilling(private val activity:Activity, engine:FlutterEngine):PurchasesUpdatedListener {
    private val channel=MethodChannel(engine.dartExecutor.binaryMessenger,"app.daypanel.next/billing")
    private val clientLazy=lazy { BillingClient.newBuilder(activity).setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()).build() }
    private val client get()=clientLazy.value
    private var product:ProductDetails?=null
    private var pending=false
    private var active:MethodChannel.Result?=null
    private var connecting=false
    private var closed=false
    private val handler=android.os.Handler(android.os.Looper.getMainLooper())
    private val timeout=Runnable { finish("unavailable") }
    init {
        channel.setMethodCallHandler { call,reply ->
            if(call.method !in listOf("status","restore","buy")){reply.notImplemented();return@setMethodCallHandler}
            if(BuildConfig.DEBUG){reply.success(mapOf("testing" to true,"owned" to false,"available" to false));return@setMethodCallHandler}
            if(BuildConfig.PLAY_PUBLIC_KEY.isBlank()){reply.success(state("unavailable"));return@setMethodCallHandler}
            if(active!=null){reply.error("busy","A purchase request is already active",null);return@setMethodCallHandler}
            active=reply;handler.postDelayed(timeout,30000)
            connect { if(call.method=="buy") purchase() else refresh() }
        }
    }
    private fun state(error:String?=null):Map<String,Any?> = mapOf(
        "owned" to PlusReceipt.owned(activity),"testing" to false,"pending" to pending,
        "available" to (clientLazy.isInitialized() && client.isReady && product?.oneTimePurchaseOfferDetails!=null),
        "price" to product?.oneTimePurchaseOfferDetails?.formattedPrice,"error" to error)
    private fun finish(error:String?=null){
        handler.removeCallbacks(timeout)
        active?.success(state(error));active=null
    }
    private fun connect(ready:()->Unit) {
        if(client.isReady){ready();return}
        if(connecting){finish("unavailable");return}
        connecting=true
        client.startConnection(object:BillingClientStateListener {
            override fun onBillingSetupFinished(result:BillingResult){
                connecting=false
                if(closed)return
                if(result.responseCode==BillingClient.BillingResponseCode.OK)ready() else finish("unavailable")
            }
            override fun onBillingServiceDisconnected(){connecting=false;if(!closed)finish("unavailable")}
        })
    }
    private fun queryProduct(then:()->Unit) {
        val params=QueryProductDetailsParams.newBuilder().setProductList(listOf(
            QueryProductDetailsParams.Product.newBuilder().setProductId(BuildConfig.PLUS_PRODUCT_ID).setProductType(BillingClient.ProductType.INAPP).build())).build()
        client.queryProductDetailsAsync(params){ result, details ->
            if(closed)return@queryProductDetailsAsync
            product=if(result.responseCode==BillingClient.BillingResponseCode.OK)details.productDetailsList.firstOrNull { it.productId==BuildConfig.PLUS_PRODUCT_ID } else null
            then()
        }
    }
    private fun refresh(){
        queryProduct {
            client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()){ result,purchases ->
                if(closed)return@queryPurchasesAsync
                if(result.responseCode!=BillingClient.BillingResponseCode.OK){finish("unavailable");return@queryPurchasesAsync}
                // A successful authoritative query revokes a refunded/absent entitlement.
                val own=purchases.filter { BuildConfig.PLUS_PRODUCT_ID in it.products }
                pending=own.any { it.purchaseState==Purchase.PurchaseState.PENDING }
                val purchased=own.firstOrNull { valid(it) }
                if(purchased==null){activity.getSharedPreferences("play_receipt",Context.MODE_PRIVATE).edit().clear().commit();finish()}
                else accept(purchased)
            }
        }
    }
    private fun valid(p:Purchase)=p.purchaseState==Purchase.PurchaseState.PURCHASED &&
        BuildConfig.PLUS_PRODUCT_ID in p.products && PlusReceipt.valid(p.originalJson,p.signature,BuildConfig.PLAY_PUBLIC_KEY,activity.packageName,BuildConfig.PLUS_PRODUCT_ID)
    private fun accept(p:Purchase){
        if(!valid(p)){finish("verification");return}
        fun save(){
            activity.getSharedPreferences("play_receipt",Context.MODE_PRIVATE).edit().putString("data",p.originalJson).putString("signature",p.signature).commit()
            pending=false;finish()
        }
        if(p.isAcknowledged){save();return}
        client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.purchaseToken).build()){ r ->
            if(closed)return@acknowledgePurchase
            if(r.responseCode==BillingClient.BillingResponseCode.OK)save() else finish("unavailable")
        }
    }
    private fun purchase(){
        queryProduct {
            val detail=product
            if(detail?.oneTimePurchaseOfferDetails==null){finish("unavailable");return@queryProduct}
            val params=BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(detail).build()
            // Do not impose a timeout on the user while the Play purchase sheet is open.
            handler.removeCallbacks(timeout)
            val r=client.launchBillingFlow(activity,BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(params)).build())
            if(r.responseCode==BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED)refresh()
            else if(r.responseCode!=BillingClient.BillingResponseCode.OK)finish("unavailable")
        }
    }
    override fun onPurchasesUpdated(result:BillingResult,purchases:MutableList<Purchase>?){
        if(closed)return
        when(result.responseCode){
            BillingClient.BillingResponseCode.USER_CANCELED -> finish("cancelled")
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> refresh()
            BillingClient.BillingResponseCode.OK -> {
                val relevant=purchases.orEmpty().filter { BuildConfig.PLUS_PRODUCT_ID in it.products }
                val paid=relevant.firstOrNull { valid(it) }
                if(paid!=null)accept(paid) else {pending=relevant.any { it.purchaseState==Purchase.PurchaseState.PENDING };finish(if(pending)null else "verification")}
            }
            else -> finish("unavailable")
        }
    }
    fun close(){closed=true;handler.removeCallbacks(timeout);active?.error("closed","Purchase screen closed",null);active=null;channel.setMethodCallHandler(null);if(clientLazy.isInitialized())client.endConnection()}
}
