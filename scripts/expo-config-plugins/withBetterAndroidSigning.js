const { withAppBuildGradle } = require('@expo/config-plugins');

// This plugin modifies the default android/app/build.gradle to use a more standard signing configuration
// based on gradle.properties and a keystore.properties file.
// It is more robust than the previous string-replacement plugin.

const signingConfig = `
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
        release {
            if (project.hasProperty('MYAPP_UPLOAD_STORE_FILE')) {
                storeFile file(MYAPP_UPLOAD_STORE_FILE)
                storePassword MYAPP_UPLOAD_STORE_PASSWORD
                keyAlias MYAPP_UPLOAD_KEY_ALIAS
                keyPassword MYAPP_UPLOAD_KEY_PASSWORD
            } else if (new File("../keystore.properties").exists()) {
                def keystoreProps = new Properties()
                keystoreProps.load(new FileInputStream(file("../keystore.properties")))
                storeFile file(keystoreProps['storeFile'])
                storePassword keystoreProps['storePassword']
                keyAlias keystoreProps['keyAlias']
                keyPassword keystoreProps['keyPassword']
            }
        }
    }
`;

module.exports = (config) => {
  return withAppBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      // Replace the entire signingConfigs block
      config.modResults.contents = config.modResults.contents.replace(
        /signingConfigs\s*{[^}]+}/,
        signingConfig
      );
    }
    return config;
  });
};
