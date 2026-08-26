package com.kasedapp

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin gérant l'installation automatique d'APK pour le système de mise à jour.
 *
 * Utilise FileProvider pour exposer l'APK au système Android et déclencher
 * l'Intent d'installation via ACTION_VIEW.
 */
class AppUpdatePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kased_app/update")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installApk" -> {
                val apkPath = call.argument<String>("apkPath")
                if (apkPath == null) {
                    result.error("INVALID_PATH", "Chemin APK manquant", null)
                    return
                }
                installApk(apkPath, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun installApk(apkPath: String, result: MethodChannel.Result) {
        try {
            val file = java.io.File(apkPath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "APK introuvable: $apkPath", null)
                return
            }

            // Obtenir l'URI via FileProvider
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.flutter.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }

            // Créer l'intent d'installation
            val intent = Intent(Intent.ACTION_VIEW).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                setDataAndType(uri, "application/vnd.android.package-archive")
            }

            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }
}
