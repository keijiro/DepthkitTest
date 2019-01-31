using Klak.Hap;
using UnityEngine;
using System.Linq;

namespace Ditho
{
    public sealed class Fiber : MonoBehaviour
    {
        #region Editable attributes

        [SerializeField] HapPlayer _source = null;
        [SerializeField] Metadata _metadata = null;

        [SerializeField] int _pointCount = 1000;
        [SerializeField] float _curveLength = 10;
        [SerializeField] float _curveAnimation = 0.02f;

        [SerializeField] float _noiseAmplitude = 0.05f;
        [SerializeField] float _noiseAnimation = 1;

        [SerializeField, ColorUsage(false, true)] Color _lineColor = Color.white;
        [SerializeField, Range(0, 1)] float _attenuation = 1;

        [SerializeField] Shader _shader = null;

        void OnValidate()
        {
            _pointCount = Mathf.Max(_pointCount, 1);
        }

        #endregion

        #region Private members

        Mesh _mesh;
        Material _material;

        void LazyInitialize()
        {
            if (_material == null)
            {
                _material = new Material(_shader);
                _material.hideFlags = HideFlags.DontSave;
            }

            if (_mesh == null)
            {
                _mesh = new Mesh();
                _mesh.hideFlags = HideFlags.DontSave;
                _mesh.name = "Fiber";
                ReconstructMesh();
            }
        }

        #endregion

        #region Internal methods

        internal void ReconstructMesh()
        {
            _mesh.Clear();
            _mesh.vertices = new Vector3[_pointCount];
            _mesh.SetIndices(
                Enumerable.Range(0, _pointCount).ToArray(),
                MeshTopology.LineStrip, 0
            );
            _mesh.bounds = new Bounds(Vector3.zero, new Vector3(1, 1, 10));
            _mesh.UploadMeshData(true);
        }

        #endregion

        #region MonoBehaviour implementation

        void OnDestroy()
        {
            Utility.Destroy(_mesh);
            Utility.Destroy(_material);
        }

        void LateUpdate()
        {
            LazyInitialize();

            _material.mainTexture = _source.texture;

            _material.SetVector("_CurveParams", new Vector2(
                _curveLength / _pointCount, _curveAnimation
            ));

            _material.SetVector("_NoiseParams", new Vector2(
                _noiseAmplitude, _noiseAnimation
            ));

            _material.SetColor("_LineColor", _lineColor);
            _material.SetFloat("_Attenuation", _attenuation);
            _material.SetFloat("_LocalTime", Time.time + 10);

            _metadata.Apply(_material);

            Graphics.DrawMesh(
                _mesh, transform.localToWorldMatrix,
                _material, gameObject.layer
            );
        }

        #endregion
    }
}
