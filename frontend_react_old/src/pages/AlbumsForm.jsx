// import React, { useState, useEffect } from 'react';
// import { Container, Row, Col, Card, Form, Button } from 'react-bootstrap';
// import { getNewReleases, searchAlbums } from '../services/spotifyService';
//
// const AlbumsForm = () => {
//   const [albums, setAlbums] = useState([]);
//   const [loading, setLoading] = useState(true);
//   const [error, setError] = useState(null);
//   const [searchQuery, setSearchQuery] = useState('');
//
//   useEffect(() => {
//     loadNewReleases();
//   }, []);
//
//   const loadNewReleases = async () => {
//     try {
//       const releases = await getNewReleases();
//       setAlbums(releases);
//       setLoading(false);
//     } catch (err) {
//       console.error('Error loading new releases:', err);
//       setError('Failed to load albums');
//       setLoading(false);
//     }
//   };
//
//   const handleSearch = async (e) => {
//     e.preventDefault();
//     if (!searchQuery.trim()) return;
//
//     setLoading(true);
//     try {
//       const results = await searchAlbums(searchQuery);
//       setAlbums(results);
//       setLoading(false);
//     } catch (err) {
//       console.error('Error searching albums:', err);
//       setError('Failed to search albums');
//       setLoading(false);
//     }
//   };
//
//   if (loading) return <div className="text-center p-5">Loading...</div>;
//   if (error) return <div className="text-center text-danger p-5">{error}</div>;
//
//   return (
//     <Container className="py-4">
//       <h2 className="mb-4">Albums</h2>
//
//       <Form onSubmit={handleSearch} className="mb-4">
//         <Row>
//           <Col md={8}>
//             <Form.Control
//               type="text"
//               placeholder="Search for albums..."
//               value={searchQuery}
//               onChange={(e) => setSearchQuery(e.target.value)}
//             />
//           </Col>
//           <Col md={4}>
//             <Button type="submit" variant="primary" className="w-100">
//               Search
//             </Button>
//           </Col>
//         </Row>
//       </Form>
//
//       <Row>
//         {albums.map((album, index) => (
//           <Col key={index} md={4} className="mb-4">
//             <Card>
//               <Card.Img
//                 variant="top"
//                 src={album.images[0]?.url}
//                 alt={album.name}
//                 style={{ height: '200px', objectFit: 'cover' }}
//               />
//               <Card.Body>
//                 <Card.Title>{album.name}</Card.Title>
//                 <Card.Text>
//                   {album.artists?.map(artist => artist.name).join(', ')}
//                 </Card.Text>
//                 <Card.Text className="text-muted">
//                   Released: {new Date(album.release_date).toLocaleDateString()}
//                 </Card.Text>
//               </Card.Body>
//             </Card>
//           </Col>
//         ))}
//       </Row>
//     </Container>
//   );
// };
//
// export default AlbumsForm;