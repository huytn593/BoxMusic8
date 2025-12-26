import React, {useState} from "react";
import {Card, Button, Badge, Alert, OverlayTrigger, Tooltip, Modal, Spinner, Container} from "react-bootstrap";
import { BadgeCheck, Star, Music, Download, Headphones, ShieldCheck, UploadCloud, Users } from "lucide-react";
import '../styles/Upgrade.css';
import {useNavigate, useParams} from "react-router-dom";
import {getPaymentsUrl} from "../services/PaymentService";
import {toast, ToastContainer} from "react-toastify";
import { useAuth } from "../context/authContext";
import {loginSessionOut, useLoginSessionOut} from "../services/loginSessionOut";

const UpgradeAccount = () => {
  const tiers = [
    {
      title: "VIP",
      icon: <BadgeCheck size={40} color="#facc15" />,
      description: [
        {
          text: "Truy cập không giới hạn",
          icon: <ShieldCheck size={18} className="text-success" />,
          detail: "Nghe nhạc và khám phá mà không giới hạn số lượt hay thời gian sử dụng."
        },
        {
          text: "Bỏ quảng cáo",
          icon: <BadgeCheck size={18} className="text-success" />,
          detail: "Trải nghiệm không bị gián đoạn bởi quảng cáo."
        },
        {
          text: "Ưu tiên hỗ trợ",
          icon: <Users size={18} className="text-success" />,
          detail: "Được ưu tiên phản hồi khi cần hỗ trợ kỹ thuật hoặc góp ý."
        }
      ],
      price: "99.000₫ / tháng",
      buttonLabel: "Nâng cấp VIP",
      priceReal: 99000,
      highlight: false,
    },
    {
      title: "Premium",
      icon: <Star size={40} color="#a855f7" />,
      description: [
        {
          text: "Chất lượng cao",
          icon: <Headphones size={18} className="text-primary" />,
          detail: "Nghe nhạc ở chất lượng lossless hoặc 320kbps."
        },
        {
          text: "Tải về không giới hạn",
          icon: <Download size={18} className="text-primary" />,
          detail: "Tải xuống không giới hạn số lượng bài hát để nghe offline."
        },
        {
          text: "Nội dung độc quyền",
          icon: <Star size={18} className="text-primary" />,
          detail: "Truy cập các album, MV và nhạc đặc biệt chỉ dành riêng cho Premium."
        }
      ],
      price: "199.000₫ / tháng",
      buttonLabel: "Nâng cấp Premium",
      priceReal: 199000,
      highlight: true,
    }
  ];

  const { logout } = useAuth();
  const { userId } = useParams();
  const navigate = useNavigate();
  const [showConfirmModal, setConfirmModal] = useState(false);
  const [selectedTier, setSelectedTier] = useState(null);
  const handleSessionOut = useLoginSessionOut();

  const [loading, setLoading] = useState(false);

  if (loading) {
    return (
        <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
          <div className="d-flex justify-content-center align-items-center vh-100">
            <Spinner animation="border" role="status" />
          </div>
        </Container>
    );
  }
  const handleClose = () => setConfirmModal(false);
  const handleConfirm = async () => {
    const tier = selectedTier;

    if (!tier) {
      toast.error("Không xác định được gói nâng cấp", {
        position: "top-center",
        autoClose: 2000
      });
      return;
    }

    else {
      let data = {
        "orderType": "billpayment",
        "amount": tier.priceReal,
        "orderDescription": `Người dùng ${userId} thanh toán gói ${tier.title}`,
        "name": `${userId}, ${tier.title}`,
      }

      setLoading(true);

      const result = await getPaymentsUrl(JSON.stringify(data));

      if (result === "Phiên đăng nhập hết hạn") {
        handleSessionOut();
      }

      else if (result === "Máy chủ đang bảo trì"){
        toast.error("Máy chủ đang bảo trì, vui lòng thử lại sau", {
          position: "top-center",
          autoClose: 2000,
          pauseOnHover: false,
        });
      }

      else if (result.url){
        window.location.href = result.url;
        setTimeout(() => {
          setLoading(false);
        }, 1000)
      }

      else {
        if (result === "Failed to fetch") {
          handleSessionOut();
        }
        else {
          toast.error(`Lỗi không xác định ${result}`, {
            position: "top-center",
            autoClose: 2000,
            pauseOnHover: false,
          });
        }
      }
      handleClose();
    }
  };

  const handleBuyClick = (tier) => {
    setSelectedTier(tier);        // Lưu lại gói được chọn
    setConfirmModal(true);        // Hiện modal xác nhận
  };

  return (
      <>
        <div className="container py-5 text-light rounded">
          <h2 className="text-center fw-bold mb-5 text-white">✨ Chọn gói nâng cấp phù hợp ✨</h2>
          <div className="row g-4 justify-content-center">
            {tiers.map((tier, index) => (
              <div className="col-12 col-md-6 col-lg-4" key={index}>
                <Card
                    className={`h-100 text-center shadow-lg upgrade-card card-hover ${
                        tier.highlight ? "border border-warning" : "border border-secondary"
                    }`}
                    bg="dark"
                    text="light"
                >
                  <Card.Body className="d-flex flex-column align-items-center justify-content-between p-4">
                    {tier.highlight && (
                        <Badge bg="warning" text="dark" className="mb-2">
                          Khuyến nghị
                        </Badge>
                    )}
                    <div className="mb-3">{tier.icon}</div>
                    <Card.Title className="fs-3 fw-bold text-white mb-3">{tier.title}</Card.Title>

                    <ul className="text-light fs-6 text-start px-3 mb-4 list-unstyled w-100">
                      {tier.description.map((item, i) => (
                          <OverlayTrigger
                              key={i}
                              placement="top"
                              overlay={<Tooltip id={`tooltip-${index}-${i}`}>{item.detail}</Tooltip>}
                              trigger={['hover', 'focus']}
                          >
                            <li className="d-flex align-items-center gap-2 mb-2 hover-glow" style={{ cursor: "pointer" }}>
                              {item.icon}
                              <span>{item.text}</span>
                            </li>
                          </OverlayTrigger>
                      ))}
                    </ul>

                    <h4 className="mb-3 text-info fw-bold">{tier.price}</h4>
                    <Button onClick={() => handleBuyClick(tier)} variant="warning" className="w-100 fs-5 fw-semibold text-dark">
                      {tier.buttonLabel}
                    </Button>
                  </Card.Body>
                </Card>
              </div>
            ))}
          </div>
          <Alert variant="info" className="mt-5 text-dark fw-semibold shadow-sm">
            <h5 className="fw-bold mb-2">Lưu ý ⚠️</h5>
            <p className="mb-0">
              Sau khi mua gói <strong>Premium</strong>, thời hạn còn lại của gói <strong>VIP</strong> sẽ bị hủy bỏ.
              Thời hạn gói nâng cấp sẽ được tính từ <strong>0 giờ</strong> ngày mua.
            </p>
            <p className="mb-0">
              Nếu có gói đang có và chưa hết hạn, khi mua gói cùng cấp sẽ được cộng thêm <strong>30 ngày</strong> vào ngày hết hạn.
            </p>
            <p className="mb-0">
              Gói nâng cấp sau khi mua sẽ không thể hoàn tiền.
            </p>
            <p className="mb-0">
              Vui lòng đọc kỹ chính sách mua hàng của chúng tôi <a href={'/policy'}>tại đây</a>
            </p>
          </Alert>

          <Modal show={showConfirmModal} onHide={handleClose} centered dialogClassName={"custom-modal-overlay"} backdrop={true}>
            <Modal.Header closeButton>
              <Modal.Title>Xác nhận mua</Modal.Title>
            </Modal.Header>
            <Modal.Body>Bạn có chắc muốn nâng cấp lên gói này không?</Modal.Body>
            <Modal.Footer>
              <Button variant="secondary" onClick={handleClose}>Hủy</Button>
              <Button variant="danger" onClick={handleConfirm}>Thanh toán</Button>
            </Modal.Footer>
          </Modal>
        </div>
        <ToastContainer />
      </>
  );
};

export default UpgradeAccount;
