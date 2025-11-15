import React from 'react';
import { View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import type { RootStackParamList } from '@/types';

export type HowToPrayScreenProps = NativeStackScreenProps<RootStackParamList, 'HowToPrayScreen'>;

const HowToPrayScreen = ({ navigation }: HowToPrayScreenProps) => {
  React.useEffect(() => {
    navigation.replace('GuidePlayerScreen', { guideId: 'how-to-pray' });
  }, [navigation]);
  return <View />;
};

export default observer(HowToPrayScreen);
