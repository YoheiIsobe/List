//
//  CustomTextField.swift
//  TableViewController
//
//  Created by 根津拓真 on 2021/05/01.
//  Copyright © 2021 Nechan. All rights reserved.
//

import UIKit
import RealmSwift

class CustomTextField: UITextField {
    //バックスペースが押されたとき
    override func deleteBackward() {
     super.deleteBackward()
        if self.text?.count == 0 {
            let realm = try! Realm()
            // デリゲート設定
            let fromAppDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
            
            //1つでも保存されていたら(一番上でなければ)
            if todos.count != 0 {
                let todo = todos[todos.count - 1]
                //テキストフィールドに表示する
                self.text = todo.text
                //データベースからは削除する
                try! realm.write {
                    realm.delete(todo)
                }
                //リロードデータ
                //TodoTableViewController().tableView.reloadData()
            }
        }
    }
}
