import { createContext, useContext } from 'react';

// Type for translation keys (can be extended for type safety)
type TranslationKey = string;

// Translation context
interface TranslationContextType {
  t: (key: TranslationKey, params?: Record<string, any>) => string;
  locale: string;
  translations: Record<string, any>;
}

// Create context
export const TranslationContext = createContext<TranslationContextType>({
  t: (key: string) => key,
  locale: 'en',
  translations: {},
});

// Hook to use translations
export const useTranslation = () => {
  const context = useContext(TranslationContext);
  if (!context) {
    throw new Error('useTranslation must be used within a TranslationProvider');
  }
  return context;
};

// Helper function to get nested value from object using dot notation
export const getNestedValue = (obj: any, path: string): any => {
  return path.split('.').reduce((current, key) => current?.[key], obj);
};

// Translation function
export const translate = (
  translations: Record<string, any>,
  key: string,
  params?: Record<string, any>
): string => {
  let translation = getNestedValue(translations, key);

  // If translation not found, return the key
  if (translation === undefined || translation === null) {
    return key;
  }

  // If translation is not a string, return the key
  if (typeof translation !== 'string') {
    console.warn(`Translation for key "${key}" is not a string`);
    return key;
  }

  // Replace parameters in the translation
  if (params) {
    Object.keys(params).forEach((param) => {
      translation = translation.replace(
        new RegExp(`\\{${param}\\}`, 'g'),
        String(params[param])
      );
    });
  }

  return translation;
};
