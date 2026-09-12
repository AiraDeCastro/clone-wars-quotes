plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.coldopen.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.coldopen.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(project(":core"))

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.glance.appwidget)
    implementation(libs.androidx.glance.material3)
}

// Keeps the bundled corpus asset from silently drifting from the repo's
// corpus/quotes.json (see TASKS.md M1 "Bundle the compiled corpus with the
// app" — this was previously a manual `npm run sync:android` step run from
// the repo root). Wired into `preBuild` so it runs before every build, not
// just when someone remembers to run the npm script by hand.
//
// Unverified: no Gradle is installed on the machine this was written on, so
// this hasn't actually been run. The task-registration pattern itself
// (Exec task depended on by preBuild) is a standard, well-documented Gradle
// idiom, and OperatingSystem.current().isWindows is the long-standing way
// Gradle scripts pick "npm.cmd" vs "npm" on Windows — but confirm this
// actually fires (and that npm is on PATH when Android Studio invokes
// Gradle) the first time this project is opened for real.
tasks.register<Exec>("syncCorpus") {
    description = "Copies corpus/quotes.json into app/src/main/assets/quotes.json."
    workingDir = rootDir.parentFile
    val npmCommand = if (org.gradle.internal.os.OperatingSystem.current().isWindows) "npm.cmd" else "npm"
    commandLine(npmCommand, "run", "sync:android")
}

tasks.named("preBuild") {
    dependsOn("syncCorpus")
}
