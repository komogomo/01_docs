// ===== Tenant Shortcut Menu (デフォルト5項目) =====
// Reference: common-frame-components_detail-design_v1.0.md 表5.2.4

console.log('Creating tenant shortcut menu...');

await prisma.tenant_shortcut_menu.createMany({
  data: [
    {
      tenant_id: demoTenant.id,
      feature_key: 'home',
      label_key: 'nav.home',
      icon: 'Home',
      display_order: 1,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'board',
      label_key: 'nav.board',
      icon: 'MessageSquare',
      display_order: 2,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'facility',
      label_key: 'nav.facility',
      icon: 'Calendar',
      display_order: 3,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'mypage',
      label_key: 'nav.mypage',
      icon: 'User',
      display_order: 4,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'logout',
      label_key: 'nav.logout',
      icon: 'LogOut',
      display_order: 5,
      enabled: true,
      status: 'active',
    },
  ],
});

console.log('✅ Tenant shortcut menu created (5 items: home/board/facility/mypage/logout)');
