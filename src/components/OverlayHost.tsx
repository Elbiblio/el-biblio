import React from 'react';
import { View, StyleSheet, SafeAreaView, ViewStyle } from 'react-native';

type Props = {
  children: React.ReactNode;
  style?: ViewStyle;
};

const OverlayHost: React.FC<Props> = ({ children, style }) => {
  return (
    <View pointerEvents="box-none" style={[styles.host, style]}>
      <SafeAreaView pointerEvents="box-none" style={StyleSheet.absoluteFill}>
        {children}
      </SafeAreaView>
    </View>
  );
};

const styles = StyleSheet.create({
  host: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    zIndex: 35,
    elevation: 5,
  },
});

export default OverlayHost;
