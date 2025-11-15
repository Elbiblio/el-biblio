import React from 'react';
import { View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import type { RootStackParamList } from '@/types';

export type HolySpiritScreenProps = NativeStackScreenProps<RootStackParamList, 'HolySpiritScreen'>;

type HolySpiritStepId = 'read' | 'meditate' | 'pray';

const HolySpiritScreen = ({ navigation }: HolySpiritScreenProps) => {
  React.useEffect(() => {
    navigation.replace('GuidePlayerScreen', { guideId: 'holy-spirit' });
  }, [navigation]);

  return <View />;

  
};
export default observer(HolySpiritScreen);
