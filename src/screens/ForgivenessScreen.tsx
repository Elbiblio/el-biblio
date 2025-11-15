import React from 'react';
import { View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import type { RootStackParamList } from '@/types';

export type ForgivenessScreenProps = NativeStackScreenProps<RootStackParamList, 'ForgivenessScreen'>;

const ForgivenessScreen = ({ navigation }: ForgivenessScreenProps) => {
  React.useEffect(() => {
    navigation.replace('GuidePlayerScreen', { guideId: 'forgiveness' });
  }, [navigation]);
  return <View />;
};

export default observer(ForgivenessScreen);
