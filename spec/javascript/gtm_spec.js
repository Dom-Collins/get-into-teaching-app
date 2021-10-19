import Gtm from 'gtm';
import Cookies from 'js-cookie';
import CookiePreferences from 'cookie_preferences';

describe('Google Tag Manager', () => {
  const mockGtag = () => {
    window.gtag = jest.fn();
  };

  const clearCookies = () => {
    Cookies.remove(CookiePreferences.cookieName);
  };

  const setupHtml = () => {
    document.body.innerHTML = '<script></script>';
  };

  const run = () => {
    const gtm = new Gtm('ABC-123');
    gtm.init();
  };

  beforeEach(() => {
    clearCookies();
    setupHtml();
  });

  describe('initialisation', () => {
    beforeEach(() => run());

    it('defines window.dataLayer', () => {
      expect(window.gtag).toBeDefined();
    });

    it('defines window.gtag', () => {
      expect(window.dataLayer).toBeDefined();
    });

    it('appends the GTM script', () => {
      const scriptTag = document.querySelector(
        "script[src^='https://www.googletagmanager.com/gtm.js?id=ABC-123']"
      );
      expect(scriptTag).not.toBeNull();
    });
  });

  describe('on Turbo page changes', () => {
    beforeEach(() => {
      mockGtag();
      run();
    });

    it('updates the page_path in GTM', () => {
      window.location.path = '/new-path';

      document.dispatchEvent(new Event('turbo:load'));

      expect(window.gtag).toHaveBeenCalledWith('set', 'page_path', '/new-path');
      expect(window.gtag).toHaveBeenCalledWith('event', 'page_view');
    });
  });

  describe('when cookies have not yet been accepted', () => {
    beforeEach(() => {
      mockGtag();
      run();
    });

    it('sends GTM defaults with all cookies denied', () => {
      expect(window.gtag).toHaveBeenCalledWith('consent', 'default', {
        analytics_storage: 'denied',
        ad_storage: 'denied',
      });
    });

    describe('when cookies are accepted', () => {
      it('updates GTM of all cookie preferences', () => {
        new CookiePreferences().setCategory('marketing', true);
        expect(window.gtag).toHaveBeenCalledWith('consent', 'update', {
          analytics_storage: 'denied',
          ad_storage: 'granted',
        });
      });
    });
  });

  describe('when cookies have already been accepted', () => {
    beforeEach(() => {
      new CookiePreferences().setCategory('non-functional', true);
      mockGtag();
      run();
    });

    it('sends GTM defaults with all cookie preferences', () => {
      expect(window.gtag).toHaveBeenCalledWith('consent', 'default', {
        analytics_storage: 'granted',
        ad_storage: 'denied',
      });
    });
  });
});