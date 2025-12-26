import React, { useState } from 'react';

const sections = [
  {
    key: 'overview',
    label: 'Tổng quan',
    content: (
      <>
        <h2 className="section-title">Tổng quan về Chính sách</h2>
        <p>
          Tại Musicresu, chúng tôi cam kết bảo vệ quyền riêng tư và dữ liệu cá nhân của bạn. Chính sách này mô tả cách chúng tôi xử lý thông tin của bạn khi sử dụng nền tảng streaming nhạc của chúng tôi.
        </p>
        <div className="section-box">
          <h4>Cam kết của chúng tôi</h4>
          <ul>
            <li>Minh bạch trong việc thu thập và sử dụng dữ liệu</li>
            <li>Bảo mật thông tin cá nhân với các biện pháp kỹ thuật tiên tiến</li>
            <li>Tôn trọng quyền kiểm soát dữ liệu của người dùng</li>
            <li>Tuân thủ các quy định pháp luật về bảo vệ dữ liệu</li>
          </ul>
        </div>
      </>
    ),
  },
  {
    key: 'collect',
    label: 'Thu thập thông tin',
    content: (
      <>
        <h2 className="section-title">Thu thập thông tin</h2>
        <p>Chúng tôi thu thập các loại thông tin sau:</p>
        <ul>
          <li>Thông tin bạn cung cấp khi đăng ký tài khoản (họ tên, email, ngày sinh...)</li>
          <li>Dữ liệu sử dụng dịch vụ (lịch sử nghe nhạc, tìm kiếm, playlist...)</li>
          <li>Thông tin thiết bị, trình duyệt, địa chỉ IP</li>
        </ul>
      </>
    ),
  },
  {
    key: 'use',
    label: 'Sử dụng thông tin',
    content: (
      <>
        <h2 className="section-title">Sử dụng thông tin</h2>
        <ul>
          <li>Cá nhân hóa trải nghiệm nghe nhạc</li>
          <li>Cải thiện dịch vụ và phát triển tính năng mới</li>
          <li>Gửi thông báo, khuyến mãi, hỗ trợ khách hàng</li>
        </ul>
      </>
    ),
  },
  {
    key: 'share',
    label: 'Chia sẻ thông tin',
    content: (
      <>
        <h2 className="section-title">Chia sẻ thông tin</h2>
        <p>Chúng tôi chỉ chia sẻ thông tin cá nhân trong các trường hợp:</p>
        <ul>
          <li>Tuân thủ pháp luật hoặc yêu cầu của cơ quan chức năng</li>
          <li>Với đối tác cung cấp dịch vụ hỗ trợ vận hành (theo hợp đồng bảo mật)</li>
        </ul>
      </>
    ),
  },
  {
    key: 'storage',
    label: 'Lưu trữ dữ liệu',
    content: (
      <>
        <h2 className="section-title">Lưu trữ dữ liệu</h2>
        <p>Chúng tôi lưu trữ dữ liệu cá nhân trong thời gian cần thiết để cung cấp dịch vụ và tuân thủ quy định pháp luật.</p>
      </>
    ),
  },
  {
    key: 'rights',
    label: 'Quyền của bạn',
    content: (
      <>
        <h2 className="section-title">Quyền của bạn</h2>
        <ul>
          <li>Truy cập, chỉnh sửa hoặc xóa thông tin cá nhân</li>
          <li>Yêu cầu hạn chế hoặc phản đối việc xử lý dữ liệu</li>
          <li>Rút lại sự đồng ý bất cứ lúc nào</li>
        </ul>
      </>
    ),
  },
  {
    key: 'cookies',
    label: 'Cookies',
    content: (
      <>
        <h2 className="section-title">Cookies</h2>
        <p>Chúng tôi sử dụng cookies để ghi nhớ tùy chọn của bạn và phân tích hành vi sử dụng nhằm cải thiện dịch vụ.</p>
      </>
    ),
  },
  {
    key: 'contact',
    label: 'Liên hệ',
    content: (
      <>
        <h2 className="section-title">Liên hệ</h2>
        <p>Nếu bạn có câu hỏi về chính sách này, vui lòng liên hệ: <a href="mailto:support@musicresu.com" style={{color:'#ff3b3f'}}>support@musicresu.com</a></p>
      </>
    ),
  },
];

export default function PolicyForm() {
  const [active, setActive] = useState('overview');

  return (
    <div className="policy-root" style={{ minHeight: '100vh', background: '#111', color: '#fff', fontFamily: 'Inter, Arial, sans-serif', padding: '32px 0' }}>
      <div className="container" style={{ maxWidth: 1300, margin: '0 auto', display: 'flex', gap: 32 }}>
        {/* Sidebar */}
        <nav style={{ minWidth: 300, background: '#18191c', borderRadius: 18, padding: '32px 0', boxShadow: '0 2px 16px rgba(0,0,0,0.12)' }}>
          <div style={{ fontSize: 22, fontWeight: 700, color: '#ff3b3f', marginLeft: 32, marginBottom: 24 }}>Mục lục</div>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {sections.map((s) => (
              <li key={s.key}>
                <button
                  onClick={() => setActive(s.key)}
                  style={{
                    width: '100%',
                    textAlign: 'left',
                    background: active === s.key ? '#ff3b3f' : 'transparent',
                    color: active === s.key ? '#fff' : '#e0e0e0',
                    border: 'none',
                    outline: 'none',
                    fontSize: 18,
                    fontWeight: 500,
                    padding: '14px 32px',
                    borderRadius: 10,
                    marginBottom: 4,
                    cursor: 'pointer',
                    transition: 'background 0.2s, color 0.2s',
                  }}
                >
                  {s.label}
                </button>
              </li>
            ))}
          </ul>
        </nav>
        {/* Content */}
        <main style={{ flex: 1, background: '#18191c', borderRadius: 18, padding: '40px 48px', boxShadow: '0 2px 16px rgba(0,0,0,0.12)', minHeight: 600, transition: 'all 0.3s' }}>
          <h1 style={{ color: '#ff3b3f', fontWeight: 800, fontSize: 38, marginBottom: 8 }}>Chính sách Quyền riêng tư</h1>
          <div style={{ color: '#bdbdbd', fontSize: 18, marginBottom: 24 }}>Cập nhật lần cuối: 15 tháng 6, 2025</div>
          <div style={{ borderLeft: '4px solid #ff3b3f', background: '#232325', color: '#e0e0e0', padding: '18px 24px', borderRadius: 12, marginBottom: 32, fontSize: 17 }}>
            Chính sách này giải thích cách Musicresu thu thập, sử dụng và bảo vệ thông tin cá nhân của bạn khi sử dụng dịch vụ streaming nhạc của chúng tôi.
          </div>
          <section style={{ minHeight: 300, transition: 'all 0.3s' }}>
            {sections.find((s) => s.key === active)?.content}
          </section>
        </main>
      </div>
    </div>
  );
} 