/**
 * Tailwind CSS Configuration for SECUREA City
 * 
 * Document ID: SEC-APP-TAILWIND-CONFIG-001
 * Version: 1.0
 * Created: 2025-10-27
 * 
 * このファイルは、Securea City Design Guideline v2.0 に基づいた
 * Tailwind CSS設定ファイルです。
 * 
 * 参照元:
 * - 01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.txt
 * - 02_DESIGN_SYSTEM_Tailwind_Specification_v1_0.md
 */

module.exports = {
  // JIT Mode（推奨）
  mode: 'jit',
  
  // Content paths for PurgeCSS
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
    './public/**/*.html',
    './pages/**/*.{js,jsx,ts,tsx}',
  ],
  
  theme: {
    extend: {
      // ==========================================
      // Color System
      // ==========================================
      colors: {
        // Primary Colors
        primary: {
          start: '#667eea',  // パープルブルー
          end: '#764ba2',    // ディープパープル
        },
        
        // Accent Colors
        accent: {
          main: '#3b82f6',   // ブルー
          light: '#60a5fa',  // ライトブルー
        },
        
        // Background Colors
        background: {
          primary: '#f9fafb',    // ホワイトグレー - メイン背景
          secondary: '#f3f4f6',  // ライトグレー - カード背景
          border: '#e5e7eb',     // ボーダーグレー - 境界線
        },
        
        // Text Colors
        text: {
          primary: '#1f2937',    // チャコールグレー - 見出し
          secondary: '#6b7280',  // ミディアムグレー - 本文
          tertiary: '#9ca3af',   // ライトグレー - 補足情報
        },
        
        // State Colors
        state: {
          success: '#10b981',  // グリーン - 成功
          warning: '#f59e0b',  // オレンジ - 警告
          error: '#ef4444',    // レッド - エラー
          info: '#3b82f6',     // ブルー - 情報
        },
      },
      
      // ==========================================
      // Typography System
      // ==========================================
      fontFamily: {
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'Noto Sans JP',
          'sans-serif',
        ],
      },
      
      fontSize: {
        'xs': ['0.875rem', { lineHeight: '1.25rem' }],  // 14px
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],  // 14px
        'base': ['1rem', { lineHeight: '1.5rem' }],     // 16px
        'md': ['1rem', { lineHeight: '1.5rem' }],       // 16px
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],  // 18px
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],   // 20px
        '2xl': ['1.5rem', { lineHeight: '2rem' }],      // 24px
      },
      
      fontWeight: {
        normal: '400',    // 通常テキスト
        medium: '500',    // 強調テキスト
        semibold: '600',  // 見出し
        bold: '700',      // 重要な見出し
      },
      
      lineHeight: {
        tight: '1.25',    // 見出し用
        normal: '1.5',    // 通常
        relaxed: '1.75',  // 読みやすさ重視
        loose: '2',       // 余白重視
      },
      
      // ==========================================
      // Spacing System
      // ==========================================
      spacing: {
        'xs': '4px',   // 0.25rem
        'sm': '8px',   // 0.5rem
        'md': '16px',  // 1rem
        'lg': '24px',  // 1.5rem
        'xl': '32px',  // 2rem
        '2xl': '48px', // 3rem
      },
      
      // ==========================================
      // Border Radius
      // ==========================================
      borderRadius: {
        'card': '12px',
        'button': '8px',
      },
      
      // ==========================================
      // Box Shadow
      // ==========================================
      boxShadow: {
        'card': '0 2px 8px rgba(0, 0, 0, 0.1)',
        'card-hover': '0 4px 16px rgba(0, 0, 0, 0.15)',
      },
      
      // ==========================================
      // Transitions
      // ==========================================
      transitionDuration: {
        'default': '200ms',
      },
      
      transitionTimingFunction: {
        'default': 'ease',
      },
      
      // ==========================================
      // Responsive Breakpoints
      // ==========================================
      screens: {
        'mobile': '0px',      // 0-599px
        'tablet': '600px',    // 600-1023px
        'desktop': '1024px',  // 1024px以上
      },
      
      // ==========================================
      // Container
      // ==========================================
      maxWidth: {
        'mobile': '420px',
        'tablet': '768px',
        'desktop': '1024px',
      },
    },
  },
  
  // ==========================================
  // Plugins
  // ==========================================
  plugins: [
    // フォーム要素のスタイリング
    require('@tailwindcss/forms')({
      strategy: 'class',
    }),
    
    // タイポグラフィプラグイン
    require('@tailwindcss/typography'),
    
    // アスペクト比
    require('@tailwindcss/aspect-ratio'),
  ],
  
  // ==========================================
  // Variants（必要に応じて拡張）
  // ==========================================
  variants: {
    extend: {
      // ホバー、フォーカス、アクティブ状態を拡張
      backgroundColor: ['active', 'disabled'],
      textColor: ['active', 'disabled'],
      opacity: ['disabled'],
      cursor: ['disabled'],
    },
  },
};
