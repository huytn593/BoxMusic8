using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace backend.Models
{
    public class PlaylistTrack
    {
        [BsonElement("_id")]
        [BsonRequired]
        public string Id { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        [BsonElement("playlist_id")]
        public string PlaylistId { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        [BsonElement("track_id")]
        public string TrackId { get; set; }

        [BsonElement("added_at")]
        public DateTime AddedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("order")]
        public int Order { get; set; } = 0;
    }
} 