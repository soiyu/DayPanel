package app.daypanel.next

import android.content.Intent
import android.graphics.Bitmap
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.Assert.*
import java.io.ByteArrayOutputStream

class CardImageDeviceTest {
 @Test fun pngShareUsesPrivateReadOnlyUriAndKeepsOriginalBytes() {
  val c=InstrumentationRegistry.getInstrumentation().targetContext
  val bitmap=Bitmap.createBitmap(24,32,Bitmap.Config.ARGB_8888);bitmap.eraseColor(android.graphics.Color.BLUE)
  val out=ByteArrayOutputStream();bitmap.compress(Bitmap.CompressFormat.PNG,100,out);bitmap.recycle()
  val bytes=out.toByteArray();val send=CardImageBridge.prepare(c,bytes)
  assertEquals(Intent.ACTION_SEND,send.action);assertEquals("image/png",send.type)
  assertEquals(Intent.FLAG_GRANT_READ_URI_PERMISSION,send.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
  val uri=send.clipData!!.getItemAt(0).uri
  assertEquals("content",uri.scheme);assertEquals("${c.packageName}.card-images",uri.authority)
  c.contentResolver.openInputStream(uri)!!.use {assertArrayEquals(bytes,it.readBytes())}
  val provider=c.packageManager.resolveContentProvider(uri.authority!!,0)!!;assertFalse(provider.exported);assertTrue(provider.grantUriPermissions)
 }
 @Test fun malformedImagesCannotOpenShare() {
  val c=InstrumentationRegistry.getInstrumentation().targetContext
  try{CardImageBridge.prepare(c,ByteArray(100));fail("invalid png must fail")}catch(_:IllegalArgumentException){}
 }
}
