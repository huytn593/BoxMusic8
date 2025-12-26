import React, { useEffect, useState } from 'react';
import { getRevenueByTimeRange, getRevenueByTier } from '../services/paymentRecordService';
import { Row, Col, Form, Button, Card, Container } from 'react-bootstrap';
import {
    LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer
} from 'recharts';
import dayjs from 'dayjs';
import '../styles/RevenueChartForm.css';

const RevenueChartForm = () => {
    const [fromDate, setFromDate] = useState('2000-01-01');
    const [toDate, setToDate] = useState('2100-01-01');
    const [tier, setTier] = useState('VIP');

    const [chartByDate, setChartByDate] = useState([]);
    const [chartByTier, setChartByTier] = useState([]);

    useEffect(() => {
        fetchChartByDate();
        fetchChartByTier();
    }, []);

    const fetchChartByDate = async () => {
        const raw = await getRevenueByTimeRange(fromDate, toDate);
        const grouped = raw.reduce((acc, cur) => {
            const date = dayjs(cur.paymentTime).format('YYYY-MM-DD');
            acc[date] = (acc[date] || 0) + cur.amount;
            return acc;
        }, {});
        const data = Object.entries(grouped).map(([date, total]) => ({ date, total }));
        setChartByDate(data);
    };

    const fetchChartByTier = async () => {
        const raw = await getRevenueByTier(tier);
        const grouped = raw.reduce((acc, cur) => {
            const date = dayjs(cur.paymentTime).format('YYYY-MM-DD');
            acc[date] = (acc[date] || 0) + cur.amount;
            return acc;
        }, {});
        const data = Object.entries(grouped).map(([date, total]) => ({ date, total }));
        setChartByTier(data);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await fetchChartByDate();
        await fetchChartByTier();
    };

    const formatMoney = (value) => {
        return `${value.toLocaleString('vi-VN')} VNĐ`;
    };

    return (
        <Container className="p-4">
            <Card className="p-4 bg-dark text-white mb-4">
                <h4 className="mb-4">🤑 Thống kê doanh thu</h4>

                <Form onSubmit={handleSubmit} className="revenue-form">
                    {/* Tier riêng hàng */}
                    <Row className="mb-3">
                        <Col md={3}>
                            <Form.Group>
                                <Form.Label>Gói nâng cấp</Form.Label>
                                <Form.Select
                                    value={tier}
                                    onChange={e => setTier(e.target.value)}
                                >
                                    <option value="VIP">VIP</option>
                                    <option value="Premium">Premium</option>
                                </Form.Select>
                            </Form.Group>
                        </Col>
                    </Row>

                    {/* Ngày và nút lọc */}
                    <Row className="g-3 align-items-end">
                        <Col md={3}>
                            <Form.Group>
                                <Form.Label>Từ ngày</Form.Label>
                                <Form.Control
                                    type="date"
                                    value={fromDate}
                                    onChange={e => setFromDate(e.target.value)}
                                />
                            </Form.Group>
                        </Col>
                        <Col md={3}>
                            <Form.Group>
                                <Form.Label>Đến ngày</Form.Label>
                                <Form.Control
                                    type="date"
                                    value={toDate}
                                    onChange={e => setToDate(e.target.value)}
                                />
                            </Form.Group>
                        </Col>
                            <Button type="submit" variant="danger" className="">
                                Lọc
                            </Button>
                    </Row>
                </Form>
            </Card>

            <Row className="mb-4">
                <Col>
                    <Card className="p-3 bg-dark text-white">
                        <h6 className="text-info">Doanh thu theo ngày (Toàn bộ)</h6>
                        <ResponsiveContainer width="100%" height={300}>
                            <LineChart data={chartByDate}>
                                <CartesianGrid stroke="#444" />
                                <XAxis dataKey="date" stroke="#ccc" />
                                <YAxis stroke="#ccc" tickFormatter={formatMoney} />
                                <Tooltip
                                    formatter={(value) => formatMoney(value)}
                                    labelFormatter={(label) => `Ngày: ${label}`}
                                    contentStyle={{ backgroundColor: '#222', borderColor: '#555' }}
                                    itemSorter={(item) => -item.value}
                                />
                                <Line
                                    type="monotone"
                                    dataKey="total"
                                    stroke="#00bcd4"
                                    strokeWidth={2}
                                    dot={{ r: 3 }}
                                />
                            </LineChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
            </Row>

            <Row>
                <Col>
                    <Card className="p-3 bg-dark text-white">
                        <h6 className="text-success">Doanh thu theo ngày (Theo gói nâng cấp)</h6>
                        <ResponsiveContainer width="100%" height={300}>
                            <LineChart data={chartByTier}>
                                <CartesianGrid stroke="#444" />
                                <XAxis dataKey="date" stroke="#ccc" />
                                <YAxis stroke="#ccc" tickFormatter={formatMoney} />
                                <Tooltip
                                    formatter={(value) => formatMoney(value)}
                                    labelFormatter={(label) => `Ngày: ${label}`}
                                    contentStyle={{ backgroundColor: '#222', borderColor: '#555' }}
                                />
                                <Line
                                    type="monotone"
                                    dataKey="total"
                                    stroke="#4caf50"
                                    strokeWidth={2}
                                    dot={{ r: 3 }}
                                />
                            </LineChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
            </Row>
        </Container>
    );
};

export default RevenueChartForm;
