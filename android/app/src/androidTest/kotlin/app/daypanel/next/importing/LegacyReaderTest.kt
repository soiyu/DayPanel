package app.daypanel.next.importing

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class LegacyReaderTest {
    private val c=InstrumentationRegistry.getInstrumentation().targetContext
    private lateinit var file:File
    @Before fun setup(){file=File.createTempFile("legacy-fixture-",".db",c.cacheDir)}
    @After fun cleanup(){file.delete()}
    private fun fixture(version:Int=25,edit:(SQLiteDatabase)->Unit={}):ByteArray {
        file.delete()
        SQLiteDatabase.openOrCreateDatabase(file,null).use { db ->
            db.version=version
            db.execSQL("CREATE TABLE Habits(id INTEGER PRIMARY KEY,name TEXT,type INTEGER,target_type INTEGER,target_value REAL,unit TEXT,freq_num INTEGER,freq_den INTEGER,archived INTEGER,position INTEGER,description TEXT${if(version>=23) ",question TEXT" else ""}${if(version>=24) ",uuid TEXT" else ""})")
            db.execSQL("CREATE TABLE Repetitions(id INTEGER PRIMARY KEY,habit INTEGER,timestamp INTEGER,value INTEGER${if(version>=25) ",notes TEXT" else ""})")
            db.execSQL("INSERT INTO Habits VALUES(1,'Imported test',1,0,2000.001,'ml',1,1,0,0,'Description'${if(version>=23) ",'Question'" else ""}${if(version>=24) ",'fixture-uuid'" else ""})")
            db.execSQL("INSERT INTO Repetitions VALUES(1,1,1767225600000,250001${if(version>=25) ",'A note'" else ""})")
            edit(db)
        }
        return file.readBytes()
    }
    @Test fun versions21Through25ReadAsSnapshotsWithoutChangingSource() {
        for(version in 21..25) {
            val bytes=fixture(version);val before=bytes.copyOf()
            val data=LegacyDatabaseReader.read(c,bytes)
            assertEquals(version,data["version"])
            val h=(data["habits"] as List<*>).single() as Map<*,*>
            assertEquals("2000.001",h["target"]);assertEquals("ml",h["unit"])
            val e=(data["entries"] as List<*>).single() as Map<*,*>
            assertEquals(250001L,e["value"]);assertEquals(if(version==25) "A note" else "",e["notes"])
            assertArrayEquals(before,bytes);assertArrayEquals(before,file.readBytes())
        }
        assertTrue(File(c.cacheDir,"legacy-import").listFiles().orEmpty().isEmpty())
    }
    @Test fun wrongHeaderUnsupportedVersionAndTruncationAreRejectedAndTempCleaned() {
        val good=fixture()
        for(bytes in listOf(ByteArray(100),good.copyOf(100),fixture(26),ByteArray(LegacyDatabaseReader.LIMIT+1))) {
            try {LegacyDatabaseReader.read(c,bytes);fail("Expected rejection")} catch(_:Exception){}
        }
        assertTrue(File(c.cacheDir,"legacy-import").listFiles().orEmpty().isEmpty())
    }
    @Test fun viewsTriggersAndInvalidTypesCannotPretendToBeSupportedTables() {
        for(bytes in listOf(
            fixture {it.execSQL("CREATE TRIGGER bad AFTER INSERT ON Habits BEGIN DELETE FROM Habits; END")},
            fixture {it.execSQL("ALTER TABLE Repetitions RENAME TO hidden");it.execSQL("CREATE VIEW Repetitions AS SELECT * FROM hidden")},
            fixture {it.execSQL("UPDATE Repetitions SET value='not a number'")},
            fixture {it.execSQL("ALTER TABLE Habits RENAME TO unknown")}
        )) {
            try {LegacyDatabaseReader.read(c,bytes);fail("Expected rejection")}catch(_:Exception){}
        }
    }
    @Test fun recordLimitAndOversizedTextFailBeforeReturningPreview() {
        val bytes=fixture {db->
            db.beginTransaction()
            try {for(i in 2..50001)db.execSQL("INSERT INTO Repetitions VALUES(?,1,1767225600000,1,'')",arrayOf(i));db.setTransactionSuccessful()}
            finally{db.endTransaction()}
        }
        try {LegacyDatabaseReader.read(c,bytes);fail("Expected limit rejection")}catch(_:Exception){}
        val text=fixture {it.execSQL("UPDATE Habits SET name=?",arrayOf("x".repeat(1001)))}
        try {LegacyDatabaseReader.read(c,text);fail("Expected text limit")}catch(_:Exception){}
    }
}
