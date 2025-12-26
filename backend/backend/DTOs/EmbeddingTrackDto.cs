namespace backend.DTOs
{
    public class EmbeddingTrackDto
    {
        public string Id { get; set; }
        public float[] Embedding {  get; set; }
    }
}
