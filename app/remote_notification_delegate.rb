# -*- coding: utf-8 -*-
module HBFav2
  module RemoteNotificationDelegate
    def application(application, didRegisterForRemoteNotificationsWithDeviceToken:deviceToken)
      user = ApplicationUser.sharedUser

      if user.hatena_id.present? and user.webhook_key.present?
        installation = PFInstallation.currentInstallation
        installation.setDeviceTokenFromData(deviceToken)
        installation.setObject(user.hatena_id, forKey:"owner")
        installation.setObject(user.webhook_key, forKey:"webhook_key")
        installation.saveInBackground
      end
    end

    def application(application, didReceiveRemoteNotification:userInfo)
      case application.applicationState
      when UIApplicationStateActive then
        # PFPush.handlePush(userInfo)

        # ## これで Notification に転送できるけどバナーはでない
        # notification = UILocalNotification.new
        # if not notification.nil? and userInfo.present? and userInfo['aps']
        #   notification.alertBody = userInfo['aps']['alert']
        #   notification.userInfo = { 'u' => userInfo['u'] }
        #   application.presentLocalNotificationNow(notification)
        # end
      when UIApplicationStateInactive then
        PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        self.handleNotificationPayload(userInfo)
      when UIApplicationStateBackground then
        PFPush.handlePush(userInfo)
      end
    end

    def handleNotificationPayload(payload)
      if payload.present? and payload['u']
        if payload['id']
          self.presentBookmarkViewControllerWithURL(payload['u'], user:payload['id'])
        else
          self.presentWebViewControllerWithURL(payload['u'])
        end
      end
    end

    def application(application, didFailToRegisterForRemoteNotificationsWithError:error)
      if error.code == 3010
        NSLog("Push notifications don't work in the simulator!")
      else
        NSLog("didFailToRegisterForRemoteNotificationsWithError: %@", error)
      end
    end

    def presentBookmarkViewControllerWithURL(url, user:user)
      app_config = ApplicationConfig.sharedConfig

      google = GoogleAPI.sharedAPI
      google.api_key = app_config.vars[:google][:api_key]
      google.expand_url(url) do |response, long_url|
        if response.ok? and long_url
          controller = HBFav2NavigationController.alloc.initWithRootViewController(
            BookmarkViewController.new.tap do |c|
              c.url = long_url
              c.user_name = user
              c.on_modal = true
            end
          )
          @viewController.presentViewController(controller)
        end
      end
    end

    def presentWebViewControllerWithURL(url)
      controller = HBFav2NavigationController.alloc.initWithRootViewController(
        WebViewController.new.tap do |c|
          c.bookmark = Bookmark.new({ :link => url })
          c.on_modal = true
        end
      )
      @viewController.presentViewController(controller)
    end
  end
end
