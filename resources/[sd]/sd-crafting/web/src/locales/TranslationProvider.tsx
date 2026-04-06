import React, { useState, useEffect, useMemo } from 'react';
import { TranslationContext, translate } from './i18n';

interface TranslationProviderProps {
  locale?: string;
  children: React.ReactNode;
}

// Cache for loaded translations to avoid re-fetching
const translationCache: Record<string, any> = {};

export const TranslationProvider: React.FC<TranslationProviderProps> = ({
  locale = 'en',
  children,
}) => {
  const [translations, setTranslations] = useState<Record<string, any>>({});
  const [currentLocale, setCurrentLocale] = useState<string>(locale);

  useEffect(() => {
    const loadTranslations = async () => {
      // Check if we have this locale in cache
      if (translationCache[locale]) {
        setTranslations(translationCache[locale]);
        setCurrentLocale(locale);
        return;
      }

      try {
        // Fetch translations from root locales folder
        const response = await fetch(`../../locales/${locale}.json`);

        if (!response.ok) {
          console.warn(`[TranslationProvider] Failed to load ${locale}.json, falling back to en`);

          // Try to load English as fallback
          if (locale !== 'en') {
            const fallbackResponse = await fetch(`../../locales/en.json`);
            if (fallbackResponse.ok) {
              const fallbackData = await fallbackResponse.json();
              translationCache['en'] = fallbackData;
              setTranslations(fallbackData);
              setCurrentLocale('en');
            }
          }
          return;
        }

        const data = await response.json();

        // Cache the translations
        translationCache[locale] = data;
        setTranslations(data);
        setCurrentLocale(locale);
      } catch (error) {
        console.error('[TranslationProvider] Error loading translations:', error);
      }
    };

    loadTranslations();
  }, [locale]);

  const t = useMemo(
    () => (key: string, params?: Record<string, any>) => {
      return translate(translations, key, params);
    },
    [translations]
  );

  const value = useMemo(
    () => ({
      t,
      locale: currentLocale,
      translations,
    }),
    [t, currentLocale, translations]
  );

  return (
    <TranslationContext.Provider value={value}>
      {children}
    </TranslationContext.Provider>
  );
};
