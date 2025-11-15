import React from 'react';
import { View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import type { RootStackParamList } from '@/types';

export type CareerDiscoveryScreenProps = NativeStackScreenProps<RootStackParamList, 'CareerDiscoveryScreen'>;

const CareerDiscoveryScreen = ({ navigation }: CareerDiscoveryScreenProps) => {
  React.useEffect(() => {
    navigation.replace('GuidePlayerScreen', { guideId: 'career-discovery' });
  }, [navigation]);
  return <View />;
};

export default observer(CareerDiscoveryScreen);
