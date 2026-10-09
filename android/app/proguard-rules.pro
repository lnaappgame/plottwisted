# Les composants Firebase (Crashlytics, Installations...) sont instanciés par
# réflexion via leur constructeur sans argument. R8 le retirait dans les
# versions release : Crashlytics manquait, Firebase.initializeApp() échouait
# côté Dart, et tout Firebase (classement, multijoueur, sauvegarde) était
# hors service sur les versions du Play Store.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
