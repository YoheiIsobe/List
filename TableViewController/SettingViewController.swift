//
//  SettingViewController.swift
//  TableViewController
//
//  Created by 根津拓真 on 2021/04/20.
//  Copyright © 2021 Nechan. All rights reserved.
//

import UIKit
import RealmSwift

class SettingViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var settingTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    // セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // セルの設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingTableView.dequeueReusableCell(withIdentifier: "settingCell", for: indexPath)
        
        cell.layer.cornerRadius = 8
        cell.textLabel?.text = "データ全消去"
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        return cell
    }
    
    
    //×ボタンでフォルダ画面に戻る
    @IBAction func pushXmark(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        //dlet cell = settingTableView.dequeueReusableCell(withIdentifier: "settingCell", for: indexPath)
        
        //全削除
        if indexPath.row == 0
        {
            allDelete()
        }
    }
    
    //全消去
    func allDelete() {
        let alert = UIAlertController(title: "全てのデータを削除しますか？", message: "この操作は取り消せません", preferredStyle: .actionSheet)
        let okButton = UIAlertAction(title: "削除する", style: .destructive) { (action) in
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "id")
        let todos = realm.objects(Task.self).sorted(byKeyPath: "date")
            
            try! realm.write {
                realm.delete(folders)
                realm.delete(todos)
            }
            
            //更新するビューはフォルダビュー
            //self.settingTableView.reloadData()
        }
        let cancelButton = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in }
        
        //ボタン追加
        alert.addAction(okButton)
        alert.addAction(cancelButton)
        //アラート表示
        present(alert, animated: true, completion: nil)
    }

}
