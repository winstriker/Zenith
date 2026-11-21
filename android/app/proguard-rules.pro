# DISABLE_GOOGLE_PLAY_SERVICES builds exclude Play Services. Geolocator still
# references it but catches NoClassDefFoundError and falls back to LocationManager.
-dontwarn com.google.android.gms.**
