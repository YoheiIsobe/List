//
//  AppDelegate.swift
//  TableViewController
//
//  Created by Nechan on 2020/02/02.
//  Copyright © 2020 Nechan. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    /* フォルダNo. */
    public var folderNumber:Int = 0
    
    var viewController: TodoTableViewController!
    
    //スキーマバージョン(新しくスキーマを追加したらこのバージョンを上げて)
    let version:UInt64 = 1
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //realmのマイグレーション
        let config = Realm.Configuration(
          // スキーマバージョン設定
          schemaVersion: version,

          // 実際のマイグレーション処理　古いスキーマバージョンのRealmを開こうとすると自動的にマイグレーションが実行
          migrationBlock: { migration, oldSchemaVersion in
            // 初めてのマイグレーションの場合、oldSchemaVersionは0
            if (oldSchemaVersion < self.version) {
              // 変更点を自動的に認識しスキーマをアップデートする（ここで勝手にするから何も書かない）
            }
          })

        // デフォルトRealmに新しい設定適用
        Realm.Configuration.defaultConfiguration = config

        // Realmを開こうとしたときスキーマバージョンが異なれば、自動的にマイグレーションが実行
        let _ = try! Realm()
        
        return true
    }

    private func applicationDidFinishLaunching(_ aNotification: Notification) {
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillTerminate(_ application: UIApplication) {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //未確定のテキストを保存
        appDelegate.viewController.addText(text: viewController.tmpText)
        //フォルダが増える場合は追加する
        appDelegate.viewController.addFolder()
        
        // アプリ終了時
        print("append")
        
        
    }

}

