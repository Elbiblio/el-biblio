const { withAppBuildGradle } = require('@expo/config-plugins');

// This is the definitive plugin to fix Android signing.
// It modifies the `hasReleaseKeystore` variable in `android/app/build.gradle`
// to check for the existence of a `keystore.properties` file in the `android` directory.
// This is the standard and most robust way to handle signing configs.

module.exports = (config) => {
  return withAppBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      const buildGradle = config.modResults.contents;

      // The regex is designed to be resilient to future Expo SDK changes.
      // It finds the `def hasReleaseKeystore = ...` line and replaces it entirely.
      const newBuildGradle = buildGradle.replace(
        /def\s+hasReleaseKeystore\s*=\s*.*project\.hasProperty\("MYAPP_UPLOAD_STORE_FILE"\).*/,
        `def hasReleaseKeystore = new File("../keystore.properties").exists()`
      );

      config.modResults.contents = newBuildGradle;
    }
    return config;
  });
};
