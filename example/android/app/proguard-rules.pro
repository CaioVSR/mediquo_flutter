# The mediquo_flutter plugin ships its keep/dontwarn rules through
# consumerProguardFiles, so this app needs no MediQuo-specific rules here.
#
# Flutter's deferred-components embedding references the Play Core library, which
# this app does not use. Suppressing it is a standard Flutter R8 concern (not a
# MediQuo one) for any app with minifyEnabled.
-dontwarn com.google.android.play.core.**
