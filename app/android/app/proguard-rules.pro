# mobile_scanner
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# Giữ native camera classes
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keepclassmembers class dev.steenbakker.mobile_scanner.** { *; }