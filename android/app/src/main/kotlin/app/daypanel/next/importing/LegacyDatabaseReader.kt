package app.daypanel.next.importing

import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import org.json.JSONObject
import java.io.File

/** File-format adapter only. Never opens the app's business database. */
object LegacyDatabaseReader {
    const val LIMIT = 8 * 1024 * 1024
    fun read(context: Context, bytes: ByteArray): Map<String, Any?> {
        require(bytes.size in 100..LIMIT && bytes.copyOfRange(0,16).contentEquals("SQLite format 3\u0000".toByteArray()))
        val root=File(context.cacheDir,"legacy-import").apply { mkdirs() }
        // Never remove another Activity's active private copy. Expired copies
        // left by a killed process are collected on the next read after a day.
        root.listFiles()?.forEach { if(it.isDirectory && System.currentTimeMillis()-it.lastModified()>86400000) it.deleteRecursively() }
        val dir=java.nio.file.Files.createTempDirectory(root.toPath(),"read-").toFile()
        try {
            val source=File(dir,"source.db");source.writeBytes(bytes)
            SQLiteDatabase.openDatabase(source.path,null,SQLiteDatabase.OPEN_READONLY).use { db ->
                require(db.version in 21..25)
                db.rawQuery("PRAGMA quick_check(1)",null).use { require(it.moveToFirst() && it.getString(0)=="ok") }
                val tables=mutableSetOf<String>()
                db.rawQuery("SELECT type,name,sql FROM sqlite_master",null).use { c ->
                    while(c.moveToNext()) {
                        require(c.getString(0) !in listOf("view","trigger"))
                        require(!(c.getString(2) ?: "").contains("VIRTUAL TABLE",ignoreCase=true))
                        if(c.getString(0)=="table")tables.add(c.getString(1).lowercase())
                    }
                }
                require(tables.containsAll(listOf("habits","repetitions")))
                fun columns(table:String):Set<String> = db.rawQuery("PRAGMA table_info($table)",null).use { c ->
                    buildSet {while(c.moveToNext())add(c.getString(1).lowercase())}
                }
                val hc=columns("Habits");val ec=columns("Repetitions")
                require(hc.containsAll(listOf("id","name","type","target_type","target_value","unit","freq_num","freq_den","archived","position","description")))
                require(ec.containsAll(listOf("id","habit","timestamp","value")))
                if(db.version>=23)require("question" in hc)
                if(db.version>=24)require("uuid" in hc)
                if(db.version>=25)require("notes" in ec)
                fun Cursor.integer(index:Int):Long {require(getType(index)==Cursor.FIELD_TYPE_INTEGER);return getLong(index)}
                fun Cursor.text(index:Int,max:Int):String {
                    if(isNull(index))return ""
                    require(getType(index)==Cursor.FIELD_TYPE_STRING)
                    return getString(index).also {require(it.length<=max)}
                }
                val habits=mutableListOf<Map<String,Any?>>()
                val optional="${if(db.version>=23) "question" else "''"},${if(db.version>=24) "uuid" else "''"}"
                db.rawQuery("SELECT id,name,type,target_type,target_value,unit,freq_num,freq_den,archived,position,description,$optional FROM Habits ORDER BY position,id LIMIT 1001",null).use { c ->
                    while(c.moveToNext()) {
                        require(c.getType(4) in listOf(Cursor.FIELD_TYPE_INTEGER,Cursor.FIELD_TYPE_FLOAT))
                        val target = if(c.getType(4)==Cursor.FIELD_TYPE_INTEGER) c.getLong(4).toString()
                            else java.math.BigDecimal.valueOf(c.getDouble(4)).stripTrailingZeros().toPlainString()
                        habits.add(mapOf("id" to c.integer(0),"name" to c.text(1,1000),"type" to c.integer(2),
                            "target_type" to c.integer(3),"target" to target,"unit" to c.text(5,100),
                            "numerator" to c.integer(6),"denominator" to c.integer(7),"archived" to c.integer(8),
                            "position" to c.integer(9),"description" to c.text(10,10000),"question" to c.text(11,10000),"uuid" to c.text(12,128)))
                    }
                }
                require(habits.size<=1000)
                val entries=mutableListOf<Map<String,Any?>>()
                db.rawQuery("SELECT habit,timestamp,value,${if(db.version>=25) "notes" else "''"} FROM Repetitions ORDER BY habit,timestamp LIMIT 50001",null).use { c ->
                    while(c.moveToNext())entries.add(mapOf("habit" to c.integer(0),"timestamp" to c.integer(1),"value" to c.integer(2),"notes" to c.text(3,10000)))
                }
                require(entries.size<=50000)
                return mapOf("version" to db.version,"habits" to habits,"entries" to entries).also {
                    require(JSONObject(it).toString().toByteArray(Charsets.UTF_8).size<=LIMIT)
                }
            }
        } finally {dir.deleteRecursively()}
    }
}
