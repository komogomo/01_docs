import React, { useState } from 'react';

export default function SecureaAppMockup() {
  const [currentScreen, setCurrentScreen] = useState('home');

  const screens = {
    home: {
      title: 'ホーム',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ 
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            borderRadius: '16px',
            padding: '30px',
            color: 'white',
            marginBottom: '24px',
            textAlign: 'center'
          }}>
            <h2 style={{ margin: '0 0 10px 0', fontSize: '24px' }}>ようこそ</h2>
            <p style={{ margin: 0, fontSize: '14px', opacity: 0.9 }}>セキュレアシティ 中央</p>
            <p style={{ margin: '8px 0 0 0', fontSize: '20px', fontWeight: 'bold' }}>田中 太郎 様</p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px', marginBottom: '24px' }}>
            {[
              { icon: '🅿️', label: '駐車場予約', screen: 'parking' },
              { icon: '📋', label: '回覧板', screen: 'notice' },
              { icon: '📹', label: '防犯カメラ', screen: 'camera' },
              { icon: '💬', label: '掲示板', screen: 'board' },
              { icon: '👁️', label: '見守り', screen: 'watch' },
              { icon: '🛒', label: '消耗品注文', screen: 'order' },
              { icon: '🔧', label: 'メンテ記録', screen: 'maintenance' },
              { icon: '⚡', label: 'エネルギー', screen: 'dhems' },
              { icon: '🔔', label: '通知', screen: 'notification' },
            ].map((item, index) => (
              <button
                key={index}
                onClick={() => setCurrentScreen(item.screen)}
                style={{
                  background: 'white',
                  border: '1px solid #e0e0e0',
                  borderRadius: '12px',
                  padding: '20px 10px',
                  textAlign: 'center',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-2px)';
                  e.currentTarget.style.boxShadow = '0 4px 8px rgba(0,0,0,0.1)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.05)';
                }}
              >
                <div style={{ fontSize: '32px', marginBottom: '8px' }}>{item.icon}</div>
                <div style={{ fontSize: '11px', color: '#333', fontWeight: 'bold' }}>{item.label}</div>
              </button>
            ))}
          </div>

          <div style={{ background: '#fff3cd', borderRadius: '12px', padding: '16px', marginBottom: '16px', borderLeft: '4px solid #ffc107' }}>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '8px' }}>⚠️ お知らせ</div>
            <div style={{ fontSize: '13px', color: '#856404' }}>台風19号接近中。窓の施錠をご確認ください。</div>
          </div>
        </div>
      )
    },
    parking: {
      title: '駐車場予約',
      content: (
        <div style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '18px', marginBottom: '20px' }}>駐車場の空き状況</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '24px' }}>
            {Array.from({ length: 12 }, (_, i) => (
              <div key={i} style={{
                background: i % 3 === 0 ? '#e8f5e9' : '#fafafa',
                border: `2px solid ${i % 3 === 0 ? '#4caf50' : '#e0e0e0'}`,
                borderRadius: '8px',
                padding: '20px 10px',
                textAlign: 'center',
                fontSize: '14px'
              }}>
                <div style={{ fontWeight: 'bold' }}>P{i + 1}</div>
                <div style={{ fontSize: '12px', marginTop: '4px', color: i % 3 === 0 ? '#2e7d32' : '#999' }}>
                  {i % 3 === 0 ? '空き' : '使用中'}
                </div>
              </div>
            ))}
          </div>
          <button style={{
            width: '100%',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            border: 'none',
            borderRadius: '12px',
            padding: '16px',
            fontSize: '16px',
            fontWeight: 'bold',
            cursor: 'pointer'
          }}>
            駐車場を予約する
          </button>
        </div>
      )
    },
    notice: {
      title: '回覧板',
      content: (
        <div style={{ padding: '20px' }}>
          {[
            { title: '自治会費の徴収について', date: '2025/10/08', unread: true },
            { title: '防災訓練のお知らせ', date: '2025/10/05', unread: true },
            { title: '清掃活動のご案内', date: '2025/10/01', unread: false },
            { title: '夏祭り開催のお知らせ', date: '2025/09/20', unread: false },
          ].map((item, index) => (
            <div key={index} style={{
              background: 'white',
              border: '1px solid #e0e0e0',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '12px',
              position: 'relative'
            }}>
              {item.unread && (
                <div style={{
                  position: 'absolute',
                  top: '16px',
                  right: '16px',
                  background: '#f44336',
                  color: 'white',
                  borderRadius: '12px',
                  padding: '2px 8px',
                  fontSize: '11px'
                }}>未読</div>
              )}
              <div style={{ fontSize: '15px', fontWeight: 'bold', marginBottom: '8px' }}>{item.title}</div>
              <div style={{ fontSize: '12px', color: '#999' }}>📅 {item.date}</div>
            </div>
          ))}
        </div>
      )
    },
    camera: {
      title: '防犯カメラ',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ marginBottom: '20px' }}>
            <label style={{ fontSize: '14px', fontWeight: 'bold', display: 'block', marginBottom: '8px' }}>カメラ選択</label>
            <select style={{
              width: '100%',
              padding: '12px',
              borderRadius: '8px',
              border: '1px solid #e0e0e0',
              fontSize: '14px'
            }}>
              <option>メインゲート</option>
              <option>駐車場エリア</option>
              <option>公園前</option>
              <option>裏門</option>
            </select>
          </div>
          <div style={{
            background: '#000',
            borderRadius: '12px',
            height: '200px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: '20px',
            position: 'relative'
          }}>
            <div style={{ color: 'white', textAlign: 'center' }}>
              <div style={{ fontSize: '48px', marginBottom: '8px' }}>📹</div>
              <div style={{ fontSize: '14px' }}>カメラ映像</div>
            </div>
            <div style={{
              position: 'absolute',
              bottom: '12px',
              left: '12px',
              background: 'rgba(255,255,255,0.9)',
              borderRadius: '6px',
              padding: '6px 12px',
              fontSize: '12px'
            }}>
              🔴 LIVE
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <button style={{
              background: 'white',
              border: '1px solid #667eea',
              borderRadius: '8px',
              padding: '12px',
              color: '#667eea',
              fontSize: '14px',
              fontWeight: 'bold',
              cursor: 'pointer'
            }}>録画を見る</button>
            <button style={{
              background: '#667eea',
              border: 'none',
              borderRadius: '8px',
              padding: '12px',
              color: 'white',
              fontSize: '14px',
              fontWeight: 'bold',
              cursor: 'pointer'
            }}>スクショ保存</button>
          </div>
        </div>
      )
    },
    board: {
      title: '掲示板',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', overflowX: 'auto' }}>
            {['すべて', '子育て', '地域情報', '趣味', 'お知らせ'].map((cat, i) => (
              <button key={i} style={{
                background: i === 0 ? '#667eea' : 'white',
                color: i === 0 ? 'white' : '#333',
                border: '1px solid #e0e0e0',
                borderRadius: '20px',
                padding: '8px 16px',
                fontSize: '13px',
                whiteSpace: 'nowrap',
                cursor: 'pointer'
              }}>{cat}</button>
            ))}
          </div>
          {[
            { title: '近くの小児科を教えてください', user: '山田さん', replies: 5, category: '子育て' },
            { title: '今週の資源ごみ回収日', user: '自治会', replies: 2, category: 'お知らせ' },
            { title: 'テニス仲間募集中！', user: '鈴木さん', replies: 8, category: '趣味' },
          ].map((post, index) => (
            <div key={index} style={{
              background: 'white',
              border: '1px solid #e0e0e0',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '12px'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', marginBottom: '8px' }}>
                <div style={{
                  width: '32px',
                  height: '32px',
                  background: '#667eea',
                  borderRadius: '50%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'white',
                  fontSize: '14px',
                  marginRight: '8px'
                }}>👤</div>
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 'bold' }}>{post.user}</div>
                  <div style={{ fontSize: '11px', color: '#999' }}>{post.category}</div>
                </div>
              </div>
              <div style={{ fontSize: '15px', marginBottom: '8px' }}>{post.title}</div>
              <div style={{ fontSize: '12px', color: '#667eea' }}>💬 {post.replies}件の返信</div>
            </div>
          ))}
          <button style={{
            position: 'fixed',
            bottom: '80px',
            right: '20px',
            width: '56px',
            height: '56px',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            border: 'none',
            borderRadius: '50%',
            fontSize: '24px',
            cursor: 'pointer',
            boxShadow: '0 4px 12px rgba(0,0,0,0.2)'
          }}>✏️</button>
        </div>
      )
    },
    order: {
      title: '消耗品注文',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ background: '#e3f2fd', borderRadius: '12px', padding: '16px', marginBottom: '20px' }}>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '8px' }}>🏠 あなたの住宅情報</div>
            <div style={{ fontSize: '13px', color: '#1565c0' }}>型番: xevo E (2020年モデル)</div>
          </div>
          <h3 style={{ fontSize: '16px', marginBottom: '16px' }}>おすすめ消耗品</h3>
          {[
            { name: '換気扇フィルター', price: '1,200円', delivery: '翌日配送可', image: '🔲' },
            { name: '引き戸の戸車セット', price: '3,800円', delivery: '3日以内', image: '🔧' },
            { name: 'キッチン水栓カートリッジ', price: '2,400円', delivery: '翌日配送可', image: '💧' },
          ].map((item, index) => (
            <div key={index} style={{
              background: 'white',
              border: '1px solid #e0e0e0',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '12px',
              display: 'flex',
              alignItems: 'center',
              gap: '16px'
            }}>
              <div style={{ fontSize: '40px' }}>{item.image}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '4px' }}>{item.name}</div>
                <div style={{ fontSize: '12px', color: '#999', marginBottom: '4px' }}>{item.delivery}</div>
                <div style={{ fontSize: '16px', color: '#667eea', fontWeight: 'bold' }}>{item.price}</div>
              </div>
              <button style={{
                background: '#667eea',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                padding: '10px 16px',
                fontSize: '13px',
                fontWeight: 'bold',
                cursor: 'pointer'
              }}>注文</button>
            </div>
          ))}
        </div>
      )
    },
    maintenance: {
      title: 'メンテナンス記録',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', borderRadius: '12px', padding: '20px', color: 'white', marginBottom: '20px' }}>
            <div style={{ fontSize: '14px', marginBottom: '8px' }}>次回点検予定</div>
            <div style={{ fontSize: '24px', fontWeight: 'bold' }}>2025年11月15日</div>
            <div style={{ fontSize: '13px', marginTop: '8px', opacity: 0.9 }}>5年目定期点検</div>
          </div>
          <h3 style={{ fontSize: '16px', marginBottom: '16px' }}>メンテナンス履歴</h3>
          {[
            { date: '2025/05/20', type: '外壁塗装', status: '完了', color: '#4caf50' },
            { date: '2024/11/10', type: '5年目定期点検', status: '完了', color: '#4caf50' },
            { date: '2024/08/05', type: '換気扇清掃', status: '完了', color: '#4caf50' },
            { date: '2023/11/15', type: '4年目定期点検', status: '完了', color: '#4caf50' },
          ].map((item, index) => (
            <div key={index} style={{
              background: 'white',
              border: '1px solid #e0e0e0',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '12px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}>
              <div style={{
                width: '40px',
                height: '40px',
                background: item.color,
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white',
                fontSize: '20px'
              }}>✓</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '4px' }}>{item.type}</div>
                <div style={{ fontSize: '12px', color: '#999' }}>📅 {item.date}</div>
              </div>
              <button style={{
                background: 'transparent',
                border: '1px solid #667eea',
                borderRadius: '6px',
                padding: '6px 12px',
                color: '#667eea',
                fontSize: '12px',
                cursor: 'pointer'
              }}>詳細</button>
            </div>
          ))}
        </div>
      )
    },
    dhems: {
      title: 'エネルギー管理',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ marginBottom: '20px' }}>
            <div style={{ display: 'flex', gap: '8px', marginBottom: '12px' }}>
              {['今日', '今週', '今月'].map((tab, i) => (
                <button key={i} style={{
                  flex: 1,
                  background: i === 0 ? '#667eea' : 'white',
                  color: i === 0 ? 'white' : '#333',
                  border: '1px solid #e0e0e0',
                  borderRadius: '8px',
                  padding: '10px',
                  fontSize: '14px',
                  cursor: 'pointer'
                }}>{tab}</button>
              ))}
            </div>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '20px' }}>
            <div style={{ background: '#fff3e0', borderRadius: '12px', padding: '16px', border: '1px solid #ffb74d' }}>
              <div style={{ fontSize: '13px', color: '#e65100', marginBottom: '8px' }}>⚡ 使用電力</div>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#e65100' }}>18.5kWh</div>
            </div>
            <div style={{ background: '#e8f5e9', borderRadius: '12px', padding: '16px', border: '1px solid #66bb6a' }}>
              <div style={{ fontSize: '13px', color: '#2e7d32', marginBottom: '8px' }}>☀️ 発電量</div>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#2e7d32' }}>22.3kWh</div>
            </div>
          </div>

          <div style={{ background: 'white', border: '1px solid #e0e0e0', borderRadius: '12px', padding: '20px', marginBottom: '16px' }}>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '16px' }}>本日の電力収支</div>
            <div style={{ height: '150px', background: '#f5f5f5', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '48px', marginBottom: '8px' }}>📊</div>
                <div style={{ fontSize: '13px', color: '#999' }}>グラフ表示エリア</div>
              </div>
            </div>
          </div>

          <div style={{ background: '#e3f2fd', borderRadius: '12px', padding: '16px', border: '1px solid #42a5f5' }}>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#1565c0' }}>💡 省エネアドバイス</div>
            <div style={{ fontSize: '13px', color: '#1565c0' }}>
              本日は発電量が使用量を上回っています。余剰電力を有効活用しましょう！
            </div>
          </div>
        </div>
      )
    },
    watch: {
      title: '見守り機能',
      content: (
        <div style={{ padding: '20px' }}>
          <div style={{ background: 'linear-gradient(135deg, #4caf50 0%, #66bb6a 100%)', borderRadius: '12px', padding: '20px', color: 'white', marginBottom: '20px', textAlign: 'center' }}>
            <div style={{ fontSize: '48px', marginBottom: '12px' }}>✓</div>
            <div style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '8px' }}>本日の確認完了</div>
            <div style={{ fontSize: '14px', opacity: 0.9 }}>2025/10/10 09:30</div>
          </div>

          <div style={{ background: 'white', border: '1px solid #e0e0e0', borderRadius: '12px', padding: '20px', marginBottom: '16px' }}>
            <div style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '16px' }}>見守り設定</div>
            <div style={{ marginBottom: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <span style={{ fontSize: '14px' }}>毎日の確認通知</span>
                <div style={{ width: '48px', height: '24px', background: '#4caf50', borderRadius: '12px', position: 'relative', cursor: 'pointer' }}>
                  <div style={{ width: '20px', height: '20px', background: 'white', borderRadius: '50%', position: 'absolute', right: '2px', top: '2px' }}></div>
                </div>
              </div>
              <div style={{ fontSize: '12px', color: '#999' }}>毎日 9:00 に通知します</div>
            </div>
            <div>
              <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '8px' }}>緊急連絡先</div>
              <div style={{ fontSize: '13px', color: '#666', marginBottom: '4px' }}>📞 田中 花子（娘）</div>
              <div style={{ fontSize: '13px', color: '#666' }}>📞 自治会事務局</div>
            </div>
          </div>

          <div style={{ background: '#fff3cd', borderRadius: '12px', padding: '16px', border: '1px solid #ffc107' }}>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#856404' }}>⚠️ 重要</div>
            <div style={{ fontSize: '13px', color: '#856404' }}>
              3日間確認がない場合、登録された緊急連絡先に自動で通知されます。
            </div>
          </div>
        </div>
      )
    },
    notification: {
      title: '通知',
      content: (
        <div style={{ padding: '20px' }}>
          {[
            { icon: '⚠️', title: '台風19号接近中', desc: '窓の施錠をご確認ください', time: '1時間前', unread: true, color: '#ff9800' },
            { icon: '📋', title: '新しい回覧板', desc: '自治会費徴収についてのお知らせ', time: '3時間前', unread: true, color: '#2196f3' },
            { icon: '🅿️', title: '駐車場予約完了', desc: 'P5 10/12 14:00-16:00', time: '5時間前', unread: false, color: '#4caf50' },
            { icon: '🔧', title: 'メンテナンス予定', desc: '明日10/11 10:00 定期点検', time: '昨日', unread: false, color: '#9c27b0' },
            { icon: '💬', title: '掲示板に返信', desc: '「小児科を教えてください」に返信がありました', time: '2日前', unread: false, color: '#00bcd4' },
          ].map((notif, index) => (
            <div key={index} style={{
              background: notif.unread ? '#f5f5f5' : 'white',
              border: '1px solid #e0e0e0',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '12px',
              display: 'flex',
              gap: '12px',
              position: 'relative'
            }}>
              {notif.unread && (
                <div style={{
                  position: 'absolute',
                  top: '12px',
                  right: '12px',
                  width: '8px',
                  height: '8px',
                  background: '#f44336',
                  borderRadius: '50%'
                }}></div>
              )}
              <div style={{
                width: '40px',
                height: '40px',
                background: notif.color,
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '20px',
                flexShrink: 0
              }}>{notif.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '4px' }}>{notif.title}</div>
                <div style={{ fontSize: '13px', color: '#666', marginBottom: '4px' }}>{notif.desc}</div>
                <div style={{ fontSize: '11px', color: '#999' }}>{notif.time}</div>
              </div>
            </div>
          ))}
        </div>
      )
    }
  };

  return (
    <div style={{ 
      maxWidth: '400px', 
      margin: '0 auto', 
      background: '#f5f5f5',
      minHeight: '100vh',
      fontFamily: "'BIZ UDPGothic', sans-serif"
    }}>
      {/* Phone Frame */}
      <div style={{ 
        background: 'white',
        borderRadius: '32px',
        boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
        overflow: 'hidden',
        position: 'relative'
      }}>
        {/* Status Bar */}
        <div style={{ 
          background: '#000',
          height: '32px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '0 20px',
          color: 'white',
          fontSize: '12px'
        }}>
          <span>9:41</span>
          <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
            <span>📶</span>
            <span>📡</span>
            <span>🔋</span>
          </div>
        </div>

        {/* Header */}
        <div style={{ 
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          padding: '16px 20px',
          color: 'white',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          {currentScreen !== 'home' && (
            <button 
              onClick={() => setCurrentScreen('home')}
              style={{
                background: 'rgba(255,255,255,0.2)',
                border: 'none',
                borderRadius: '8px',
                color: 'white',
                padding: '8px 12px',
                cursor: 'pointer',
                fontSize: '14px'
              }}
            >← 戻る</button>
          )}
          <h1 style={{ 
            fontSize: '20px',
            margin: 0,
            flex: 1,
            textAlign: currentScreen === 'home' ? 'left' : 'center'
          }}>
            {currentScreen === 'home' ? '🏘️ セキュレア' : screens[currentScreen].title}
          </h1>
          {currentScreen === 'home' && (
            <button style={{
              background: 'rgba(255,255,255,0.2)',
              border: 'none',
              borderRadius: '50%',
              width: '36px',
              height: '36px',
              color: 'white',
              cursor: 'pointer',
              fontSize: '18px'
            }}>⚙️</button>
          )}
        </div>

        {/* Content Area */}
        <div style={{ 
          minHeight: '600px',
          maxHeight: '600px',
          overflowY: 'auto',
          background: '#f8f9fa'
        }}>
          {screens[currentScreen].content}
        </div>

        {/* Bottom Navigation */}
        {currentScreen === 'home' && (
          <div style={{ 
            display: 'flex',
            justifyContent: 'space-around',
            padding: '12px 0',
            background: 'white',
            borderTop: '1px solid #e0e0e0'
          }}>
            {[
              { icon: '🏠', label: 'ホーム', active: true },
              { icon: '📋', label: '回覧板', active: false },
              { icon: '💬', label: '掲示板', active: false },
              { icon: '👤', label: 'マイページ', active: false }
            ].map((item, index) => (
              <button key={index} style={{
                background: 'transparent',
                border: 'none',
                cursor: 'pointer',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '4px',
                color: item.active ? '#667eea' : '#999',
                fontSize: '11px'
              }}>
                <span style={{ fontSize: '24px' }}>{item.icon}</span>
                <span>{item.label}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Instructions */}
      <div style={{ 
        background: 'white',
        borderRadius: '12px',
        padding: '20px',
        marginTop: '20px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
      }}>
        <h3 style={{ fontSize: '16px', marginBottom: '12px' }}>💡 画面イメージの使い方</h3>
        <p style={{ fontSize: '14px', color: '#666', lineHeight: '1.6', margin: 0 }}>
          各アイコンをクリックすると、該当する機能画面が表示されます。「戻る」ボタンでホーム画面に戻ります。
        </p>
      </div>
    </div>
  );
}