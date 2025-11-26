const { withAppBuildGradle } = require('@expo/config-plugins');

// This plugin configures Android release signing using keystore.properties file.
// It injects the complete signing configuration into build.gradle.

module.exports = (config) => {
  return withAppBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      let buildGradle = config.modResults.contents;

      // Check if we already have our custom signing config
      if (buildGradle.includes('// CUSTOM SIGNING CONFIG')) {
        return config;
      }

      // Find the signingConfigs block - match only the signingConfigs block, not the android block closing brace
      // The pattern matches: signingConfigs { ... } but stops at the first } that closes signingConfigs
      const signingConfigPattern = /signingConfigs\s*\{\s*debug\s*\{[^}]*\}[^}]*\}/;
      
      if (signingConfigPattern.test(buildGradle)) {
        // Replace existing signingConfigs block
        buildGradle = buildGradle.replace(
          signingConfigPattern,
          `// CUSTOM SIGNING CONFIG
    def keystorePropertiesFile = file("../keystore.properties")
    def hasReleaseKeystore = keystorePropertiesFile.exists()
    
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
        release {
            if (hasReleaseKeystore) {
                def keystoreProperties = new Properties()
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
            } else {
                // Fallback to debug for local development
                storeFile file('debug.keystore')
                storePassword 'android'
                keyAlias 'androiddebugkey'
                keyPassword 'android'
            }
        }
    }`
        );
      }

      // Update buildTypes.release to use the correct signing config
      buildGradle = buildGradle.replace(
        /(release\s*\{[^}]*)(signingConfig\s+signingConfigs\.debug)/,
        '$1signingConfig signingConfigs.release'
      );

      config.modResults.contents = buildGradle;
    }
    return config;
  });
};
