//
//  ViewController.swift
//  TaskApp
//
//  Created by UI3 on 2024/11/18.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Realmインスタンスを取得する

    let realm = try! Realm()
    
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self //追記
    }
    
    // segueで画面遷移するときによばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row] //このtaskを、InputViewControllerで定義する
        } else {
            inputViewController.task = Task()
        }
    }
    
    // 入力画面から戻ってきたときにtable viewを更新させる
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    
    
    // 検索する
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 { // 検索されている文字列がない時
            configureTableView() // 全てのタスクを表示
            DispatchQueue.main.async {
                searchBar.resignFirstResponder() // 検索バーのフォーカスを外す
            }
        } else {
            // categoryを検索する
            let realm = try! Realm()
            taskArray = realm.objects(Task.self).filter("category CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "date", ascending: true)
            tableView.reloadData() // 検索後にテーブルビューを更新
        }
    }
    
    // 検索する② 全タスクを表示するための設定
    func configureTableView() {
        let realm = try! Realm()
        taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        tableView.reloadData() // 全タスクを表示するための再描画
    }
    
    
    
    // データの数（セルの数）を返すメソッド。データの配列であるtaskArrayの要素数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する  --- ここから ---　taskArrayから該当するデータを取り出してセルに設定
        let task = taskArray[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString:String = formatter.string(from: task.date)
        content.secondaryText = dateString
        cell.contentConfiguration = content
        // --- ここまで追加 ---
        
        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // --- ここから ---
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id.stringValue)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        } // --- ここまで変更 ---
    }
}
