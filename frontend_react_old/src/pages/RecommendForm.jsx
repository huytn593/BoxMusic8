import React, { useEffect, useState } from 'react';
import { Container, Spinner, Badge } from 'react-bootstrap';
import { PlayCircle, Info } from 'lucide-react';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { useNavigate, useParams } from 'react-router-dom';
import { getRecommendTrack } from '../services/recommendService';
import { useLoginSessionOut } from '../services/loginSessionOut';
import '../styles/Recommend.css';

const MusicCard = ({ id, title, subtitle, imageUrl, isPublic, onPlay, onInfo }) => {
    return (
        <div className="music-card" onClick={onInfo}>
            <div className="card-image-container">
                <img src={imageUrl || '/images/default-music.jpg'} alt={title} className="card-image" />
                {!isPublic && (
                    <Badge bg="warning" text="dark" className="vip-badge-recommend">
                        👑 VIP
                    </Badge>
                )}
                <div className="card-overlay">
                    <button className="play-button border-0 bg-transparent" onClick={(e) => { e.stopPropagation(); onPlay(); }}>
                        <PlayCircle size={60} color="white" />
                    </button>
                </div>
            </div>
            <div className="card-info">
                <div className="card-title" title={title}>{title}</div>
                <div className="card-subtitle">{subtitle}</div>
            </div>
        </div>
    );
};

const RecommendForm = () => {
    const [recommendSongs, setRecommendSongs] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const navigate = useNavigate();
    const { playTrackList } = useMusicPlayer();
    const { userId } = useParams();
    const handleSessionOut = useLoginSessionOut();

    useEffect(() => {
        const fetchData = async () => {
            setIsLoading(true);
            try {
                const recommendList = await getRecommendTrack(userId, handleSessionOut);

                const lists = recommendList.map((track, index) => ({
                    id: track.id || index,
                    title: track.title || `Bài hát ${index + 1}`,
                    subtitle: 'Gợi ý cho bạn',
                    imageUrl: track.imageBase64 || '/images/default-music.jpg',
                    isPublic: track.isPublic,
                }));

                setRecommendSongs(lists);
            } catch (error) {
                console.error("Failed to fetch recommended tracks:", error);
            } finally {
                setIsLoading(false);
            }
        };
        fetchData();
    }, [userId]);

    const handlePlay = (track) => {
        const index = recommendSongs.findIndex(t => t.id === track.id);
        if (index !== -1) {
            playTrackList(recommendSongs, index);
        }
    };

    const handleInfo = (track) => {
        navigate(`/track/${track.id}`);
    };

    if (isLoading) {
        return (
            <div className="recommend-page d-flex justify-content-center align-items-center">
                <Spinner animation="border" role="status" variant="light" />
            </div>
        );
    }

    return (
        <div className="recommend-page">
            <Container fluid className="recommend-container">
                <h2 className="recommend-title">Dành cho bạn</h2>
                <p className="text-light mb-4" style={{ fontSize: '1.1rem', opacity: 0.8 }}>Dựa vào những bài hát bạn đã nghe gần đây</p>
                {recommendSongs.length > 0 ? (
                    <div className="recommend-grid">
                        {recommendSongs.map(track => (
                            <MusicCard
                                key={track.id}
                                {...track}
                                onPlay={() => handlePlay(track)}
                                onInfo={() => handleInfo(track)}
                            />
                        ))}
                    </div>
                ) : (
                    <div className="text-center text-light p-5">
                        <div style={{ fontSize: '1.2rem', marginBottom: '1rem' }}>
                            Không có bài hát gợi ý nào.
                        </div>
                        <div className="text-muted">
                            Hãy nghe thêm nhiều bài hát để chúng tôi có thể gợi ý cho bạn!
                        </div>
                    </div>
                )}
            </Container>
        </div>
    );
};

export default RecommendForm;
