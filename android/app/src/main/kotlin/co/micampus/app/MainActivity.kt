package co.micampus.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Edge-to-edge on Android 15+ (targetSdk 36); backward-compatible on older API levels.
        WindowCompat.enableEdgeToEdge(window)
        super.onCreate(savedInstanceState)
    }
}
