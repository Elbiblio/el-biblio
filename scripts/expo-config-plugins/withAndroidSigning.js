const { withAppBuildGradle } = require('@expo/config-plugins');

// This is the definitive plugin to fix Android signing.
// It modifies the `hasReleaseKeystore` variable in `android/app/build.gradle`
// to check for the existence of a `keystore.properties` file in the `android` directory.
// This is the standard and most robust way to handle signing configs.

module.exports = (config) => {
  return withAppBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      let buildGradle = config.modResults.contents;

      // Replace the hasReleaseKeystore definition if it exists
      // This regex matches the multi-line definition that Expo generates
      buildGradle = buildGradle.replace(
        /def\s+hasReleaseKeystore\s*=\s*project\.hasProperty\("MYAPP_UPLOAD_STORE_FILE"\)\s*&&[\s\S]*?project\.hasProperty\("MYAPP_UPLOAD_KEY_PASSWORD"\)/,
        `def hasReleaseKeystore = new File("../keystore.properties").exists()`
      );

      // Also update the signingConfigs.release block to read from keystore.properties
      // if the file exists, instead of relying on project properties
      if (buildGradle.includes('signingConfigs')) {
        buildGradle = buildGradle.replace(
          /(release\s*\{[\s\S]*?if\s*\(hasReleaseKeystore\)\s*\{[\s\S]*?)(storeFile\s+file\(MYAPP_UPLOAD_STORE_FILE\)[\s\S]*?keyPassword\s+MYAPP_UPLOAD_KEY_PASSWORD)/,
          `$1def keystorePropertiesFile = new File("../keystore.properties")
                def keystoreProperties = new Properties()
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']`
        );
      }

      config.modResults.contents = buildGradle;
    }
    return config;
  });
};
