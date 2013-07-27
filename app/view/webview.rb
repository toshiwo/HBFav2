module HBFav2
  class WebView < UIWebView
    def stopLoading
      NSLog("stop loading")
      super
      App.shared.networkActivityIndicatorVisible = false
    end

    def dealloc
      NSLog("dealloc: " + self.class.name)
      super
    end
  end
end
