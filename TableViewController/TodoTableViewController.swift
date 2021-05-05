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
    
    //設定系変数
    var paddingWidth: Int = 20          /*セル左側の空白幅(初期設定はディスプレイ幅376以上に合わせて20、375以下は16にする) */
    let maxLength: Int = 21             /* セルに入れられる最大文字数 */
    let labelMaxLength: Int = 10        /* ラベルに入れられる最大文字数 */
    let fontSize: CGFloat! = 17         /* フォントサイズ設定 */
    var initialTitleSet = false         //新規作成時にタイトル設定するフラグ
    var closeWithEnter = false          //エンターキーで閉じるフラグ
    var strikeThrough = true           //取消線を引く
    
    //インスタンス系変数等
    let fromAppDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate        /* デリゲート */
    let label = UILabel()               /* ラベル生成 */
    var info: [AnyHashable: Any] = [:]  /* キーボードの情報 */
    var screenHeight:CGFloat!           /* Screenの高さ */
    var screenWidth:CGFloat!            /* Screenの幅 */
    var tmpText = ""                    /* 入力文字列の一時保存用 */
    var titleLabelChange = true         /* タイトルラベル変更中 */
    let defaults = UserDefaults.standard    /* ユーザーデフォルト　*/
    var bannerView: GADBannerView!      /* 広告 */
    
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

        textField.delegate = self   /* テキストフィールドのデリゲート設定 */
        scrollView.delegate = self  /* スクロールビューのデリゲート設定 */
        
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
        textField.font = UIFont.systemFont(ofSize: fontSize)
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        //完了ボタンを非表示、無効
        doneButton.isEnabled = false
        doneButton.title = ""
        
        //ユーザー設定を読み込み
        initialTitleSet = defaults.bool(forKey: "Title")
        closeWithEnter = defaults.bool(forKey: "EnterKey")
        strikeThrough = defaults.bool(forKey: "StrikeThrough")
        
        // タイトルラベルを太文字
        label.font = UIFont.boldSystemFont(ofSize: 17)
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
        //bannerView.adUnitID = "ca-app-pub-4013798308034554/1853863648"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        /* ---------------------広告終了---------------------------- */
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
        
        //フォルダのIDを参照して、保持しているタイトルを表示。(fromAppDelegate.folderNumberはidとの紐付けに使う。タイトルはFolder側で保存している値)
        let realm = try! Realm()
        let folders = realm.objects(Folder.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        label.text = folders[0].text
        label.sizeToFit()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(TodoTableViewController.labelTapped))
        label.addGestureRecognizer(tap)
        // ラベル設定
        label.isUserInteractionEnabled = true
        //ナビゲーションバーのタイトルを更新
        self.navigationItem.titleView = label
    }
    
    //レイアウト処理前に呼ばれる
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // テーブルビューの高さをセルの高さと合わせる
        tableViewHeight.constant = CGFloat(tableView.contentSize.height)
    }
    
    // 画面に表示される直前に呼ばれる
    override func viewDidAppear(_ animated: Bool) {
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        let folder = realm.objects(Folder.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        
        /* 1つもタスクがなければ */
        if(todos.count == 0){
            /* 新規作成時かつ、ユーザー設定ON */
            if folder[0].titleChanged == false && initialTitleSet == true {
                //タイトル変更のアラートを出す。初回変更なのでtrue
                changeTitle(initial: true)
            } else {
                /* キーボードを開く */
                textField.becomeFirstResponder()
            }
        }
    }

    /* ---------------------セル設定---------------------------- */
    //テーブルビューにセクションをいくつ作成するか
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    // セルの個数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber)
        
        return todos.count
    }
    //セルの設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: fontSize)
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.frame.size.width += 200
        
        //テキストの呼び出し
        let realm = try! Realm()
        let todos = realm.objects(Task.self).filter("id == %@",fromAppDelegate.folderNumber).sorted(byKeyPath: "date")
        let todo = todos[indexPath.row]
        //テキストを反映
        cell.textLabel?.text = todo.text
        
        //チェックマーク設定呼び出し
        checkText(selectCell: cell, checkMark: todo.check)

        return cell
    }
    
    
    /* ---------------------ユーザー操作----------------------------- */
    //タイトルラベルがタップされたとき
    @objc func labelTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        //2回目以降の変更なのでfalse
        changeTitle(initial: false)
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
        try! realm.write {
            if todo.check == false {
                todo.check = true
            } else {
                todo.check = false
            }
        }
        checkText(selectCell: cell!, checkMark: todo.check)
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

    // エンターが押されたとき
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
            //追加後、保存用テキストを削除
            tmpText = ""
            //リロード
            self.tableView.reloadData()
            // キーボードが重なっていたらスクロールさせる
            scrollUpdate()
        } else {
            // ユーザー設定がONであれば、キーボードを閉じる
            if closeWithEnter == true {
                textField.resignFirstResponder()
            }
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
    
    //ラベル変更
    func changeTitle (initial: Bool) {
        // ラべル変更中
        titleLabelChange = true
        
        var displayTitle :String
        if initial == true {
            displayTitle = "タイトルを設定"
        } else {
            displayTitle = "タイトルを変更"
        }

        let realm = try! Realm()
        let folders = realm.objects(Folder.self).sorted(byKeyPath: "date")
        let folder = folders.filter("id == %@",fromAppDelegate.folderNumber)
        
        var uiTextField = UITextField()
        
        let alert = UIAlertController(title: displayTitle, message: "このリストの名前を入力してください。", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { [self] (action) in
            try! realm.write {
                //タイトル変更完了状態にする
                folder[0].titleChanged = true
                // 何か入力されて入れば
                if (uiTextField.text! != "") {
                    //リスト名を保存
                    folders[self.fromAppDelegate.folderNumber].text = uiTextField.text!
                    self.label.text = folders[self.fromAppDelegate.folderNumber].text
                    self.label.sizeToFit()
                    //リロード
                    self.tableView.reloadData()
                }
            }
            // ラベル変更中を解除
            self.titleLabelChange = false
            //初回のタイトル変更であれば
            if (initial == true) {
                /* キーボードを開く */
                textField.becomeFirstResponder()
            }
        }
        //テキストフィールド追加
        alert.addTextField { (textField) in
            /* テキストフィールドに薄く表示 */
            if initial == true {
                textField.placeholder = "◯◯◯リスト"
            } else {
                //前回のタイトルを表示
                textField.placeholder = self.label.text
            }
            //タイトルラベルの文字数制限
            guard let text = uiTextField.text else { return }
            uiTextField.text = String(text.prefix(self.labelMaxLength))
            uiTextField = textField
            /* キーボードの改行ボタンを[完了]にする */
            textField.returnKeyType = .done
        }
        //OKボタン追加
        alert.addAction(action)
        //アラート表示
        present(alert, animated: true, completion: nil)
    }
    
    //チェック機能
    func checkText(selectCell: UITableViewCell, checkMark: Bool){
        if checkMark == true {
            //チェックマーク
            //selectCell.accessoryType = .checkmark
            //透明にする
            selectCell.textLabel?.textColor = .systemGray4
            //設定がONであれば
            if strikeThrough == true {
                //取り消し線を引く
                let atr =  NSMutableAttributedString(string: (selectCell.textLabel?.text)!)
                atr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, atr.length))
                selectCell.textLabel?.attributedText = atr
            }
        }else{
            //チェックマーク解除
            //selectCell.accessoryType = .none
            //透明を解除する
            selectCell.textLabel?.textColor = .none
            //取り消し線をなくす
            let atr =  NSMutableAttributedString(string: (selectCell.textLabel?.text)!)
            atr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, 0))
            selectCell.textLabel?.attributedText = atr
        }
    }
    
    //テキストが更新されたとき(文字を保存)
    @IBAction func textChanged(_ textField: UITextField) {
        tmpText = textField.text!
    }
    
    //テキストが更新されたとき
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 入力を反映させたテキストを取得する(文字数制限)
        let resultText: String = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if resultText.count <= maxLength {
            return true
        }
        return false
    }
    
    //フォルダ追加
    func addFolder() {
        //+ボタンで遷移した場合
        if fromAppDelegate.add == true{
            let realm = try! Realm()
            let folder = Folder()
            //idを設定
            folder.id = fromAppDelegate.folderNumber
            //dateを設定
            folder.date = Date()
            //テキストを反映
            folder.text = ("リスト " + String(fromAppDelegate.folderNumber + 1))
            //タイトル変更未実施状態にする
            folder.titleChanged = false
            //データベースに書き込み
            try! realm.write {
                realm.add(folder)
            }
            //リロード
            self.tableView.reloadData()
            //フォルダ重複保存防止
            fromAppDelegate.add = false
        }
    }

    // キーボードが表示された時
    @objc func keyboardWillShow(_ notification: Notification) {
        //完了ボタンを有効、表示
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
    
    
    
    /* TodoTableView終了時 */
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
        print(tmpText)
        //未確定のテキストを保存
        addText(text: tmpText)
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
