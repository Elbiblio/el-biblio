import {
    useFonts,
    CrimsonPro_400Regular,
    CrimsonPro_500Medium,
    CrimsonPro_600SemiBold,
    CrimsonPro_400Regular_Italic,
  } from '@expo-google-fonts/crimson-pro';
  import {
    PlusJakartaSans_400Regular,
    PlusJakartaSans_500Medium,
    PlusJakartaSans_600SemiBold,
  } from '@expo-google-fonts/plus-jakarta-sans';
  
  export const useAppFonts = () => {
    const [fontsLoaded] = useFonts({
      CrimsonPro_400Regular,
      CrimsonPro_500Medium,
      CrimsonPro_600SemiBold,
      CrimsonPro_400Regular_Italic,
      PlusJakartaSans_400Regular,
      PlusJakartaSans_500Medium,
      PlusJakartaSans_600SemiBold,
    });
  
    return fontsLoaded;
  };