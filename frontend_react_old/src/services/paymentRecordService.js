const API_BASE = `${process.env.REACT_APP_API_BASE_URL}/api/PaymentRecord`;

export const getRevenueByTimeRange = async (from, to) => {
    const url = `${API_BASE}/by-time?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Lỗi lấy doanh thu theo thời gian');
    return await res.json();
};

export const getRevenueByTier = async (tier) => {
    const url = `${API_BASE}/by-tier?tier=${encodeURIComponent(tier)}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Lỗi lấy doanh thu theo tier');
    return await res.json();
};
