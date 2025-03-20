import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

// Global initialization state outside of React
// This allows importing from any file without circular dependencies
export const appState = {
  isInitialized: false
};

// React context for components that need to react to changes
const AppInitializationContext = createContext({
  isInitialized: false,
  setInitialized: (_value: boolean) => {}
});

export const AppInitializationProvider = ({ children }: { children: ReactNode }) => {
  const [isInitialized, setIsInitialized] = useState(false);
  
  useEffect(() => {
    if (isInitialized) {
      appState.isInitialized = true;
    }
  }, [isInitialized]);
  
  return (
    <AppInitializationContext.Provider 
      value={{ 
        isInitialized, 
        setInitialized: setIsInitialized 
      }}
    >
      {children}
    </AppInitializationContext.Provider>
  );
};

export const useAppInitialization = () => useContext(AppInitializationContext); 