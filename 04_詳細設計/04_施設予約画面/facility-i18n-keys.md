# 施設予約機能 辞書定義 (facility.json)

**Document ID**: HARMONET-FACILITY-BOOKING-I18N-001
**Version**: 1.0
**Date**: 2025-12-02

## 概要
施設予約機能で使用する静的文言の定義。
`public/locales/{lang}/facility.json` として実装する。

## 定義内容

### JA (Japanese)
```json
{
  "rules": {
    "fee": "使用料: {{price}}円/回",
    "payment": "支払方法: 使用前に集会所備え付けの集金ボックスに入金",
    "hours": "使用時間: 原則 {{start}} より {{end}} まで",
    "max_limit": "最大使用回数: {{count}}回/月",
    "alcohol": "遵守事項: 集会所では原則飲酒、喫煙をしないこと。ただし、飲酒については理事長が認めた場合はその限りではない。その他規定は管理規約使用細則を参照。",
    "reservation_method": "予約方法: 貸切での利用に限り、居住者用ホームページ（本サイト）上での予約が必要。"
  },
  "labels": {
    "purpose": "使用目的",
    "participant_count": "参加人数",
    "equipment": "備品利用",
    "notes": "特記事項",
    "vehicle_number": "車両ナンバー",
    "vehicle_model": "車種"
  }
}
```

### EN (English)
```json
{
  "rules": {
    "fee": "Fee: {{price}} JPY/time",
    "payment": "Payment: Please deposit the fee into the collection box at the meeting room before use.",
    "hours": "Hours: Generally from {{start}} to {{end}}",
    "max_limit": "Limit: {{count}} times/month",
    "alcohol": "Rules: Alcohol and smoking are prohibited in the meeting room. Exceptions for alcohol may be granted by the chairperson. Refer to the management bylaws for details.",
    "reservation_method": "Reservation: Reservations via this website are required only for private use."
  },
  "labels": {
    "purpose": "Purpose of Use",
    "participant_count": "Number of Participants",
    "equipment": "Equipment Use",
    "notes": "Notes"
  }
}
```

### ZH (Chinese - Simplified)
```json
{
  "rules": {
    "fee": "使用费: {{price}}日元/次",
    "payment": "支付方式: 请在使用前将费用投入集会所的收款箱。",
    "hours": "使用时间: 原则上从 {{start}} 到 {{end}}",
    "max_limit": "最大使用次数: {{count}}次/月",
    "alcohol": "遵守事项: 集会所内原则上禁止饮酒和吸烟。饮酒需经理事长批准。详情请参阅管理规约细则。",
    "reservation_method": "预约方法: 仅限包场使用时，需通过本网站进行预约。"
  },
  "labels": {
    "purpose": "使用目的",
    "participant_count": "参加人数",
    "equipment": "设备使用",
    "notes": "备注"
  }
}
```
