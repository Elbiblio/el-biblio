const { getDefaultConfig } = require('expo/metro-config');

/**
 * Metro configuration for Expo SDK 53 / RN 0.79
 * - enable package exports so resolver honors package.json "exports"
 * - prefer CommonJS by including 'require' before 'react-native'/'default'
 *   to avoid ESM builds that use `import.meta` (e.g., zustand@5)
 */
const config = getDefaultConfig(__dirname);

config.resolver = config.resolver || {};
config.resolver.unstable_enablePackageExports = true;
config.resolver.unstable_conditionNames = [
  'require',
  'react-native',
  'default',
];

module.exports = config;
