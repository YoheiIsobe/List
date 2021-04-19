//
//  TodoTableViewController.swift
//  TableViewController
//
//  Created by Nechan on 2020/02/26.
//  Copyright © 2020 Nechan. All rights reserved.
//

import UIKit
import RealmSwift
import AudioToolbox
import GoogleMobileAds

class TodoTableViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate ,UITextFieldDelegate, UIGestureRecognizerDelegate, UITableViewDragDelegate, UITableViewDropDelegate{

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldHeight: NSLayoutConstraint!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    // キーボードの情報
    var info: [AnyHashable: Any] = [:]
    // Screenの高さ
    var screenHeight:CGFloat!
    // Screenの幅
    var screenWidth:CGFloat!

    // デリゲート設定
    let fromAppDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // セル左側の空白幅(初期設定はディスプレイ幅376以上に合わせて20、375以下は16にする)
    var paddingWidth: Int = 20
    
    /* セルに入れられる最大文字数 */
    var maxLength: Int = 20
    
    var tmpText = ""
    
    //タイトルラベル変更中
    var titleLabelChange = true
    
    //ラベル生成
    let label = UILabel()
    
    /* 広告 */
    var bannerView: GADBannerView!
    
    //起動時に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // appデリゲート設定(アプリ終了時の処理に必要)
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = self
        
        // ドラッグ&ドロップのデリゲート設定
        tableView.dataSource = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        // テキストフィールドのデリゲート設定
        textField.delegate = self
        // スクロールビューのデリゲート設定
        scrollView.delegate = self
        
        // 画面サイズ取得
        let screenSize: CGRect = UIScreen.main.bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        // 表示窓のサイズと位置を設定
        scrollView.frame.size =
            CGSize(width: screenWidth, height: screenHeight)
        // UIScrollViewに追加
        scrollView.addSubview(tableView)
        scrollView.addSubview(textField)
        // ビューに追加
        self.view.addSubview(scrollView)
        
        // ディスプレイ幅375以下:16、376以上:20
        if(screenWidth <= 375) {
            paddingWidth = 16
        }
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: paddingWidth, height: 0))
        //入力テキストサイズ
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.leftView = paddingView
        textField.leftViewMode = .always

        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        /* 1つもタスクがなければ */
        if(todos.count == 0){
            /* キーボードを開く */
            textField.becomeFirstResponder()
        }

        doneButton.isEnabled = false
        doneButton.title = ""
        
        // ラベル変更完了に初期化
        self.titleLabelChange = false
        /* キーボードの改行ボタンを[完了]にする */
        textField.returnKeyType = .done
        //チェックマークを複数選択可
        tableView.allowsMultipleSelection = true
        // スクロールの跳ね返り無し
        scrollView.bounces = false

        // テーブルビューの上辺を、スクロールビューの上辺と同じにする
        tableView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        // テキストフィールドの下辺を、スクロールビューの下辺と同じにする
        textField.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        // テキストフィールドをした方向に伸ばす
        textFieldSizeUpdate()
        /* ---------------------広告開始---------------------------- */
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.rootViewController = self
        //本番　ca-app-pub-4013798308034554/1853863648
        //テスト　ca-app-pub-3940256099942544/2934735716
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        /* ---------------------広告終了---------------------------- */
    }

    /* ---------------------内部設定---------------------------- */
    //テーブルビューにセクションをいくつ作成するか
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //テーブルビューにセルをいくつ表示させるか
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber)
        
        return todos.count
    }
    
    //セルの設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.frame.size.width += 200
        
        //テキストの呼び出し
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        let todo = todos[indexPath.row]
        //テキストを反映
        cell.textLabel?.text = todo.text
        
        //チェックマークが付いていたら
        if todo.check == true {
            checkText(selectCell: cell, checkMark: true)
        }else{
            cell.accessoryType = .none
            checkText(selectCell: cell, checkMark: false)
        }
        return cell
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // テーブルビューの高さをセルの高さと合わせる
        tableViewHeight.constant = CGFloat(tableView.contentSize.height)
    }

    /* ---------------------ユーザー操作----------------------------- */
    
    // タイトルラベルタップ
    @objc func labelTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        // ラべル変更中
        titleLabelChange = true
        
        let realm = try! Realm()
        let folder = realm.objects(Folder.self).sorted(byKeyPath: "id")
        
        var uiTextField = UITextField()
        let alert = UIAlertController(title: "リスト名を変更", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { [self] (action) in
            // 何か入力されて入れば
            if (uiTextField.text! != "") {
                try! realm.write {
                    //リスト名を保存
                    folder[self.fromAppDelegate.folderNumber].text = uiTextField.text!
                    self.label.text = folder[self.fromAppDelegate.folderNumber].text
                    self.label.sizeToFit()
                    //リロード
                    self.tableView.reloadData()
                }
            }
            // ラベル変更完了
            self.titleLabelChange = false
        }
        //テキストフィールド追加
        alert.addTextField { (textField) in
            textField.placeholder = folder[self.fromAppDelegate.folderNumber].text
            uiTextField = textField
        }
        //OKボタン追加
        alert.addAction(action)
        //アラート表示
        present(alert, animated: true, completion: nil)
    }
    
    // セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath)
        print("tap!")

        AudioServicesPlaySystemSound(1519)

        //セルの背景色をフェード表示させる
        tableView.deselectRow(at: indexPath, animated: false)
        //テキストの呼び出し
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        let todo = todos[indexPath.row]
        //反転
        if todo.check == false {
            try! realm.write {
                todo.check = true
            }
            checkText(selectCell: cell!, checkMark: true)
        }else{
            try! realm.write {
                todo.check = false
            }
            checkText(selectCell: cell!, checkMark: false)
        }
    }
    
    // ドラッグ
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        AudioServicesPlaySystemSound(1519)
        return []
    }
    // ドロップ
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
    
    // 単体削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //セルの横線設定を削除
            let cell = tableView.cellForRow(at: indexPath)
            checkText(selectCell: cell!, checkMark: false)
            
            //データ削除
            let realm = try! Realm()
            let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
            let todo = todos[indexPath.row]

            try! realm.write {
                realm.delete(todo)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        // タスクが削除されたときに、レイアウトを更新（入力カーソルの高さを合わせる)
        viewWillLayoutSubviews()
        // テキストフィールドをした方向に伸ばす
        textFieldSizeUpdate()
    }

    // エンターが押された時の処理
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if var text = textField.text {
            //文字数制限
            text = String(text.prefix(maxLength))
            //テキスト追加
            self.addText(text: text)
        }
        return true
    }
    
    // 完了ボタン押下
    @IBAction func pushDoneButton(_ sender: Any) {
        //未確定のテキストを保存
        addText(text: tmpText)
        
        // キーボードを閉じる
        textField.resignFirstResponder()
    }
    
    /* ---------------------共通関数----------------------------- */
    //テーブルビューに追加処理
    func addText(text: String){
        //空白ではない場合
        if text != "" {
            let realm = try! Realm()
            let todo = Task()
            //idを設定
            todo.id = fromAppDelegate.folderNumber
            //dateを設定
            todo.date = Date()
            //テキストを反映
            todo.text = text
            //データベースに書き込み
            try! realm.write {
                realm.add(todo)
            }
            /* テキストフィールド内の文字を削除 */
            textField.text = ""
            //保存後、テキストを削除
            tmpText = ""
            //リロード
            self.tableView.reloadData()
            
            // キーボードが重なっていたらスクロールさせる
            scrollUpdate()
        }
        else{
            // キーボードを閉じる
            //textField.resignFirstResponder()
        }
    }
    
    //入れ替え制御
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        
        try! realm.write {
            /* セルを下から上に移動 */
            if(sourceIndexPath.row > destinationIndexPath.row){
                for i in 0 ..<  (sourceIndexPath.row - destinationIndexPath.row){
                    let sourceCell = todos[sourceIndexPath.row - i]
                    let DestinationCell = todos[sourceIndexPath.row - i - 1]
                    let tmpCell = Task()
                    
                    tmpCell.date = sourceCell.date
                    sourceCell.date = DestinationCell.date
                    DestinationCell.date = tmpCell.date
                }
                
            /* セルを上から下に移動 */
            }else if(sourceIndexPath.row < destinationIndexPath.row){
                for i in 0 ..<  (destinationIndexPath.row - sourceIndexPath.row){
                    let sourceCell = todos[sourceIndexPath.row + i]
                    let DestinationCell = todos[sourceIndexPath.row + i + 1]
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
    
    //文字にチェックマークをつける
    func checkText(selectCell: UITableViewCell, checkMark: Bool){
        if checkMark == true {
            selectCell.textLabel?.textColor = .systemGray4
            //cell?.accessoryType = .checkmark
            
            //取り消し線を引く
            let atr =  NSMutableAttributedString(string: (selectCell.textLabel?.text)!)
            atr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, atr.length))
            selectCell.textLabel?.attributedText = atr
        }else{
            selectCell.textLabel?.textColor = .none
            //selectCell.accessoryType = .none
            
            //取り消し線をなくす
            let atr =  NSMutableAttributedString(string: (selectCell.textLabel?.text)!)
            atr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, 0))
            selectCell.textLabel?.attributedText = atr
        }
    }
    
    //テキストが更新されたとき
    @IBAction func textChanged(_ textField: UITextField) {
        tmpText = textField.text!
    }
    
    // 画面に表示される直前に呼ばれる
    override func viewWillAppear(_ animated: Bool) {
        // キーボード通知
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(self.keyboardWillShow(_:)),
               name: UIResponder.keyboardWillShowNotification,
               object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(self.keyboardWillHide(_:)) ,
               name: UIResponder.keyboardDidHideNotification,
               object: nil)
        
        
        //フォルダが増える場合は追加する
        addFolder()
        
        let realm = try! Realm()
        let folder = realm.objects(Folder.self).sorted(byKeyPath: "id")
        
        label.text = folder[fromAppDelegate.folderNumber].text
        label.sizeToFit()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(TodoTableViewController.labelTapped))
        label.addGestureRecognizer(tap)
        // ラベル設定
        label.isUserInteractionEnabled = true
        //ナビゲーションバーのタイトルを更新
        self.navigationItem.titleView = label
    }
    
    // viewが表示されなくなる直前に呼ばれる(FolderViewへ遷移するとき)
    override func viewWillDisappear(_ animated: Bool) {
          super.viewWillDisappear(animated)
          
        // キーボード通知
        NotificationCenter.default.removeObserver(self,
               name: UIResponder.keyboardWillShowNotification,
              object: self.view.window)
        NotificationCenter.default.removeObserver(self,
               name: UIResponder.keyboardDidHideNotification,
              object: self.view.window)
        
        //未確定のテキストを保存
        addText(text: tmpText)
        
        //バックボタン
        if self.isMovingFromParent {
            //todoの数が0であれば消す
            let realm = try! Realm()
            let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
            
            if (todos.count == 0) {
                let folders = realm.objects(Folder.self).sorted(byKeyPath: "id")
                
                let deleteFolder = folders.filter("id == %@",fromAppDelegate.folderNumber)
                let deleteTodos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
                
                try! realm.write {
                    realm.delete(deleteFolder)
                    realm.delete(deleteTodos)
                    
                    //削除したフォルダより下にあるフォルダを抽出
                    for i in 0 ..<  (folders.count - fromAppDelegate.folderNumber)
                    {
                        let underFolder = folders[fromAppDelegate.folderNumber + i]
                        let underTasks = realm.objects(Task.self).filter("id == %@", fromAppDelegate.folderNumber + i + 1).sorted(byKeyPath: "date")
                        
                        underFolder.id -= 1

                        //フォルダ内のタスクのidを更新する。（ポインタなのでidを更新したタスクから、underTasks配列から無くなっていく)
                        for _ in 0 ..<  underTasks.count
                        {
                            underTasks[0].id -= 1
                        }
                    }
                }
            }
        }
    }
    
    //フォルダ追加
    func addFolder() {
        let realm = try! Realm()
        //let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        let folders = realm.objects(Folder.self)
        
        if (fromAppDelegate.folderNumber >= folders.count) {
            let folder = Folder()
            //idを設定
            folder.id = fromAppDelegate.folderNumber
            //テキストを反映
            folder.text = ("リスト " + String(folders.count + 1))
            //データベースに書き込み
            try! realm.write {
                realm.add(folder)
            }
            
            //リロード
            self.tableView.reloadData()
        }
    }

    // キーボードが表示された時
    @objc func keyboardWillShow(_ notification: Notification) {
        doneButton.title = "完了"
        doneButton.isEnabled = true
        
        // キーボード情報を保存
        info = notification.userInfo!
        
        // テキストフィールドとキーボードの重なりを確認して、必要であればスクロールする
        scrollUpdate()
    }
    
    // キーボードが閉じた時
    @objc func keyboardWillHide(_ notification: Notification) {
        doneButton.isEnabled = false
        doneButton.title = ""
    }
    
    // キーボードが重なっていたらスクロールさせる
    func scrollUpdate(){
        let keyboardFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        // テキストフィールドの上辺
        let topTextField = textField.frame.origin.y
        // キーボードの上辺
        let topKeyboard = screenHeight - keyboardFrame.size.height
        // 重なり
        let distance = topTextField - topKeyboard
        
        // テキストフィールドをした方向に伸ばす
        textFieldSizeUpdate()
        
        // ラベル変更中でなければ
        if titleLabelChange != true {
            // テキストフィールドがキーボードの上辺に被っている
            if distance >= -150 {
                // scrollViewのコンテツを上へオフセット + 190.0(追加のオフセット)
                scrollView.contentOffset.y = distance + 190.0
            // 被っていない
            } else {
                // scrollViewのコンテツを固定させる
                scrollView.contentOffset.y = 0
            }
        }
    }
    
    // テキストフィールドをした方向に伸ばす共通関数
    func textFieldSizeUpdate(){
        textFieldHeight.constant = CGFloat(screenHeight + tableViewHeight.constant)
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
