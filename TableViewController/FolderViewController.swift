//
//  FolderViewController.swift
//  TableViewController
//
//  Created by 根津拓真 on 2021/03/07.
//  Copyright © 2021 Nechan. All rights reserved.
//

import UIKit
import RealmSwift
import AudioToolbox
import GoogleMobileAds

class FolderViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate {
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    let rgba = UIColor(red: 44/255, green: 138/255, blue: 255/255, alpha: 1.0)
    let rgbb = UIColor(red: 44/255, green: 138/255, blue: 255/255, alpha: 0.2)
    
    //最大保存可能フォルダ数
    var maxFolderCount = 20
    
    let fromAppDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    /* 広告 */
    var bannerView: GADBannerView!
    
    // 初期表示時に必要な処理を設定
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFix()
        
        // テーブルビューのプロパティ
        tableView.layer.cornerRadius = 8
        tableView.layer.shadowOffset = CGSize(width: 0, height: 0)
        tableView.layer.shadowRadius = 3
        tableView.layer.shadowOpacity = 0.3
        tableView.layer.shadowPath = UIBezierPath(roundedRect: tableView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8, height: 8)).cgPath
        tableView.layer.shouldRasterize = true
        tableView.layer.rasterizationScale = UIScreen.main.scale
        
        // +ボタンのプロパティ
        addButton.layer.borderWidth = 2
        addButton.layer.borderColor = rgba.cgColor
        addButton.layer.cornerRadius = 25
        addButton.setTitleColor(rgba, for: UIControl.State.normal)
        
        // ドラッグ&ドロップのデリゲート設定
        tableView.dataSource = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        //リロード
        self.tableView.reloadData()

        /* ---------------------広告開始---------------------------- */
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.rootViewController = self
        // Set the ad unit ID to your own ad unit ID here.
        //本番　ca-app-pub-4013798308034554/1853863648
        //テスト　ca-app-pub-3940256099942544/2934735716
        bannerView.adUnitID = "ca-app-pub-4013798308034554/1853863648"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        /* ---------------------広告終了---------------------------- */
    }

    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    // セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let realm = try! Realm()
        let folders = realm.objects(Folder.self)
        
        return folders.count
    }
    
    // セルの設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath)
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
        
        cell.textLabel?.text = folders[indexPath.row].text
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        return cell
    }
    
    // 画面に表示される直前に呼ばれる(起動時、遷移後)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //リロードデータ
        tableView.reloadData()
        //テーブルビューの高さをセルの高さと合わせる
        updateTableHeight()
        //一番下のセルにスクロール
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
        if folders.count > 0 {
            let indexPath = NSIndexPath(row: folders.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath as IndexPath, at:.bottom, animated: false)
        }
    }

    // レイアウト処理開始時(起動時、遷移後)
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //テーブルビューの高さをセルの高さと合わせる
        updateTableHeight()
    }
    
    // セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
        fromAppDelegate.folderNumber = folders[indexPath.row].id
        //フォルダを追加しない
        fromAppDelegate.add = false
        performSegue(withIdentifier: "goToTodoTableView", sender: self)
    }
    
    // ボタンに指が触れた瞬間
    @IBAction func TouchDownButton(_ sender: Any) {
        addButton.layer.borderColor = rgbb.cgColor
        AudioServicesPlaySystemSound(1519)
    }
    
    // ボタンから遠くで指が離れたとき
    @IBAction func TouchDragOutsideButton(_ sender: Any) {
        addButton.setTitleColor(rgba, for: UIControl.State.normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0775) {
            self.addButton.layer.borderColor = self.rgba.cgColor
        }
    }
    
    // ボタンから近くで指が離れたとき
    @IBAction func pushWriteButton(_ sender: Any) {
        addButton.setTitleColor(rgba, for: UIControl.State.normal)
        addButton.layer.borderColor = rgba.cgColor
        
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
            
        //フォルダの個数制限（暫定対応）
        if folders.count < maxFolderCount {
            //idが空いていなければ末尾の番号を送る
            fromAppDelegate.folderNumber = folders.count
            
            for i in 0 ..< folders.count {
                //空いているidを探して、TodoTableViewControllerに送る
                if folders.filter("id == %@", i).count == 0
                {
                    fromAppDelegate.folderNumber = i
                    break
                }
            }
            //フォルダを追加する
            fromAppDelegate.add = true
            performSegue(withIdentifier: "goToTodoTableView", sender: self)
            
        } else {
            let alert = UIAlertController(title: "上限に達しました", message: "新しくフォルダを作成するには、\nフォルダを1つ削除してください", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "OK", style: .default) { (action) in }
            //ボタン追加
            alert.addAction(okButton)
            //アラート表示
            present(alert, animated: true, completion: nil)
        }
    }
    
    //デバッグ用ボタン
    @IBAction func debugButtonPush(_ sender: Any) {
        let realm = try! Realm()
        
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
        let todos = realm.objects(Task.self).sorted(byKeyPath: "id")
        print(folders)
        print(todos)
    }
    
    //日付情報修正
    func dateFix(){
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = fmt.date(from: "1970-01-01 9:0:0")!
        
        let realm = try! Realm()
        //前バージョンはIDでソートしていたため
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "id")
        
        print(folders.count)
        
        for i in 0 ..< folders.count {
            if folders[i].date == date {
                try! realm.write {
                    folders[i].date = Calendar.current.date(byAdding: .day, value: i + 1, to: folders[i].date)!
                    print("回数:",i)
                }
            }
        }
    }
    
    //設定画面から戻ってきたときに実行する関数
    func callBack() {
        //リロードデータ
        tableView.reloadData()
    }
    
    // 単体削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            let realm = try! Realm()
            let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
            
            let deleteFolder = folders[indexPath.row]
            let deleteTodos = realm.objects(Task.self).filter("id == %@",deleteFolder.id).sorted(byKeyPath: "date")
            
            try! realm.write {
                realm.delete(deleteFolder)
                realm.delete(deleteTodos)
            }
            //データをリロード
            tableView.reloadData()
            //テーブルビューの高さ調節
            updateTableHeight()
        }
    }
    
    //テーブルビューの高さ調節共通関数
    func updateTableHeight() {
        //制約更新を即座に実行
        tableView.layoutIfNeeded()
        //制約の更新を実行 
        tableView.updateConstraints()
        //テーブルビューの高さをセルの高さと合わせる
        tableViewHeight.constant = CGFloat(tableView.contentSize.height)
    }
    
    
    // ドラッグ
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        AudioServicesPlaySystemSound(1519)
        return []
    }
    // ドロップ
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
    
    //入れ替え制御
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")

        try! realm.write {
            /* セルを下から上に移動 */
            if(sourceIndexPath.row > destinationIndexPath.row){
                for i in 0 ..<  (sourceIndexPath.row - destinationIndexPath.row){
                    let sourceCell = folders[sourceIndexPath.row - i]
                    let DestinationCell = folders[sourceIndexPath.row - i - 1]
                    let tmpCell = Task()

                    tmpCell.date = sourceCell.date
                    sourceCell.date = DestinationCell.date
                    DestinationCell.date = tmpCell.date
                }
                
            /* セルを上から下に移動 */
            }else if(sourceIndexPath.row < destinationIndexPath.row){
                for i in 0 ..<  (destinationIndexPath.row - sourceIndexPath.row){
                    let sourceCell = folders[sourceIndexPath.row + i]
                    let DestinationCell = folders[sourceIndexPath.row + i + 1]
                    let tmpCell = Task()

                    tmpCell.date = sourceCell.date
                    sourceCell.date = DestinationCell.date
                    DestinationCell.date = tmpCell.date
                }
            }
            /* 何もしない */
            else{
            }
        }
    }

    /* ---------------------------------広告開始----------------------------------------- */
    func addBannerViewToView(_ bannerView: UIView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            positionBannerAtTopOfSafeArea(bannerView)
        }
        else {
            positionBannerAtTopOfView(bannerView)
        }
    }
    @available (iOS 11, *)
    func positionBannerAtTopOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Centered horizontally.
        let guide: UILayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate(
            [bannerView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
             bannerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)]
        )
    }
    func positionBannerAtTopOfView(_ bannerView: UIView) {
        // Center the banner horizontally.
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        // Lock the banner to the top of the bottom layout guide.
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0))
    }
    /* --------------------------------広告終了-------------------------------------------- */
}
