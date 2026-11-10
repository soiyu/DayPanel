package app.daypanel.next

import android.util.Base64
import org.junit.Assert.*
import org.junit.Test
import java.security.KeyPairGenerator
import java.security.Signature
import org.json.JSONObject

class PlusPurchaseDeviceTest {
 @Test fun signedPurchaseChecksPackageProductStateAndToken(){
   val pair=KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
   val key=Base64.encodeToString(pair.public.encoded,Base64.NO_WRAP)
   fun check(state:Int=0,product:String="daypanel_plus",pkg:String="app.daypanel.next",token:String="test-token"):Boolean {
     val raw=JSONObject().put("packageName",pkg).put("productId",product).put("purchaseState",state).put("purchaseToken",token).toString()
     val sign=Signature.getInstance("SHA1withRSA").apply{initSign(pair.private);update(raw.toByteArray())}.sign()
     return PlusReceipt.valid(raw,Base64.encodeToString(sign,Base64.NO_WRAP),key,"app.daypanel.next","daypanel_plus")
   }
   assertTrue(check());assertFalse(check(state=2));assertFalse(check(state=1));assertFalse(check(product="other"));assertFalse(check(pkg="other"));assertFalse(check(token=""))
 }
 @Test fun tamperedUnsignedAndMissingKeyNeverGrantPurchase(){
   assertFalse(PlusReceipt.valid("{}","","","app.daypanel.next","daypanel_plus"))
   val pair=KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
   val raw="{\"packageName\":\"app.daypanel.next\",\"productId\":\"daypanel_plus\",\"purchaseState\":0,\"purchaseToken\":\"t\"}"
   val signature=Signature.getInstance("SHA1withRSA").apply{initSign(pair.private);update(raw.toByteArray())}.sign()
   assertFalse(PlusReceipt.valid(raw.replace("\"t\"","\"changed\""),Base64.encodeToString(signature,Base64.NO_WRAP),Base64.encodeToString(pair.public.encoded,Base64.NO_WRAP),"app.daypanel.next","daypanel_plus"))
 }
}
