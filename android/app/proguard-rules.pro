# Regras do R8 para o build de release.
# O engine e o embedding do Flutter ja trazem suas proprias regras; aqui ficam
# apenas as excecoes do app.

# Flutter: o engine ja traz as regras de consumo que mantem o que e usado por JNI.
# Nao manter o pacote inteiro aqui, senao a ofuscacao do DEX cai.
-dontwarn io.flutter.embedding.**

# Play Core (deferred components do Flutter): classes opcionais que nao usamos.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Atributos usados por reflexao em anotacoes e genericos.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
