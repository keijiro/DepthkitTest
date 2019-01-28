using UnityEngine;

class CustomRenderer : MonoBehaviour
{
    [SerializeField] string _fileName = "Test";

    [SerializeField, HideInInspector] Shader _shader = null;

    Klak.Hap.HapPlayer _video;
    Material _material;

    static Depthkit.Depthkit_Metadata LoadMetadata(string name)
    {
        var path = System.IO.Path.Combine(
            Application.streamingAssetsPath,
            name + ".txt"
        );
        var json = System.IO.File.ReadAllText(path);
        return Depthkit.Depthkit_Metadata.CreateFromJSON(json);
    }

    static void ApplyMetadata(Depthkit.Depthkit_Metadata metadata, Material material)
    {
        var pers = metadata.perspectives[0];
        material.SetVector("_Crop", pers.crop);
        material.SetVector("_ImageDimensions", pers.depthImageSize);
        material.SetVector("_FocalLength", pers.depthFocalLength);
        material.SetVector("_PrincipalPoint", pers.depthPrincipalPoint);
        material.SetFloat("_NearClip", pers.nearClip);
        material.SetFloat("_FarClip", pers.farClip);
        material.SetMatrix("_Extrinsics", pers.extrinsics);
    }

    void Start()
    {
        _video = gameObject.AddComponent<Klak.Hap.HapPlayer>();
        _video.Open(_fileName + ".mov");

        _material = new Material(_shader);
        ApplyMetadata(LoadMetadata(_fileName), _material);
    }

    void OnRenderObject()
    {
        _material.SetTexture("_MainTex", _video.texture);
        _material.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
        _material.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Points, 1024 * 1024, 1);
    }
}
