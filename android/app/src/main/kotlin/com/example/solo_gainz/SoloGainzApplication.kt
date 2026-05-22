package com.example.solo_gainz

import android.app.Activity
import android.app.Application
import android.os.Bundle

class SoloGainzApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        registerActivityLifecycleCallbacks(UcropFullscreenLifecycle())
    }
}

private class UcropFullscreenLifecycle : Application.ActivityLifecycleCallbacks {
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        applyIfUcrop(activity)
    }

    override fun onActivityResumed(activity: Activity) {
        applyIfUcrop(activity)
    }

    override fun onActivityStarted(activity: Activity) {
        applyIfUcrop(activity)
    }

    private fun applyIfUcrop(activity: Activity) {
        if (activity.javaClass.name == UCROP_ACTIVITY) {
            ImmersiveUi.apply(activity)
        }
    }

    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}

    companion object {
        private const val UCROP_ACTIVITY = "com.yalantis.ucrop.UCropActivity"
    }
}
