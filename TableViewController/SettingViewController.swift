//
//  SettingViewController.swift
//  TableViewController
//
//  Created by 根津拓真 on 2021/04/20.
//  Copyright © 2021 Nechan. All rights reserved.
//

import UIKit
import RealmSwift

class SettingViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate, UIAdaptivePresentationControllerDelegate {
    @IBOutlet weak var settingTableView: UITableView!
    
    //エンターキーで閉じるフラグ
    //var CloseEnterKey = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // データ全削除時、フォルダビュー更新用
    override func viewWillAppear(_ animated: Bool) {
        presentingViewController?.beginAppearanceTransition(false, animated: animated)
        super.viewWillAppear(animated)
    }

    // データ全削除時、フォルダビュー更新用
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presentingViewController?.beginAppearanceTransition(true, animated: animated)
        presentingViewController?.endAppearanceTransition()
    }

    // データ全削除時、フォルダビュー更新用
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentingViewController?.endAppearanceTransition()
    }

    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    //セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    // セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 1
        
        if section == 0 {
            cellCount = 2
//        } else if section == 1{
//            cellCount = 2
        } else {
            cellCount = 1
        }
        
        return cellCount
    }
    
    // セルの設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingTableView.dequeueReusableCell(withIdentifier: "settingCell", for: indexPath)
        
        cell.layer.cornerRadius = 8
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            
        
        switch indexPath.section {
        //セクション0
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "ツイートする"
            case 1:
                cell.textLabel?.text = "ご意見・ご感想"
            default:
                break
            }
        //セクション1
//        case 1:
//            switch indexPath.row {
//            case 0:
//                let sw = UISwitch()
//                cell.textLabel?.text = "空白入力を許可"
//                cell.accessoryView = sw
//            case 1:
//                let sw = UISwitch()
//                cell.textLabel?.text = "Enterでキーボードを閉じる"
//                cell.accessoryView = sw
//            default:
//                break
//            }
        //セクション1
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "データ全消去"
            default:
                break
            }
        default :
            break
        }

        
        return cell
    }
    
    //×ボタンでフォルダ画面に戻る
    @IBAction func pushXmark(_ sender: Any) {
        // 画面を閉じる
        self.dismiss(animated: true, completion: nil)
    }
    
    // セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)

        //セクション0
        if indexPath.section == 0
        {
            //ツイート
            if indexPath.row == 0
            {
                shareOnTwitter()
            }
            //レビュー
            else if indexPath.row == 1
            {
                toReview()
            }
        }
        
//        セクション1
//        else if indexPath.section == 1
//        {
//            // 空白タップ許可
//            if indexPath.row == 0
//            {
//
//            }
//            // キーボードでクローズ
//            else if indexPath.row == 1
//            {
//                CloseEnterKey = true
//
//                let defaults = UserDefaults.standard
//                defaults.set(CloseEnterKey, forKey: "SETTING")
//            }
//        }
        //セクション1
        else if indexPath.section == 1
        {
            // 全削除
            if indexPath.row == 0
            {
                allDelete()
            }
        }
    }
    
    //ツイート機能
    func shareOnTwitter() {
        //シェアするテキストを作成
        let text = "箇条書きアプリ List.\n#買い物リスト\n#Todoリスト\n#仕事効率化https://apps.apple.com/jp/app/list/id1503882707&action=write-review"
        let hashTag = "#List."
        let completedText = text + "\n" + hashTag

        //作成したテキストをエンコード
        let encodedText = completedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        //エンコードしたテキストをURLに繋げ、URLを開いてツイート画面を表示させる
        if let encodedText = encodedText,
            let url = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            UIApplication.shared.open(url)
        }
    }
    
    //レビュー画面遷移機能
    func toReview (){
        guard let url = URL(string: "https://itunes.apple.com/app/id1503882707?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
    
    //全消去機能
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
